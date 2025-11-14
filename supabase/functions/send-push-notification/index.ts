import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.42.0";
import { initializeApp, getApp, cert } from "npm:firebase-admin@12.0.0/app";
import { getMessaging } from "npm:firebase-admin@12.0.0/messaging";

// A helper function to initialize Firebase only once, with detailed error reporting.
function initializeFirebase() {
  try {
    getApp();
    return { success: true, error: null }; // App is already initialized
  } catch (e) {
    try {
      const serviceAccountString = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");

      if (!serviceAccountString || serviceAccountString.trim() === "") {
        return { success: false, error: "FCM_SERVICE_ACCOUNT_JSON secret is missing or empty." };
      }

      const serviceAccount = JSON.parse(serviceAccountString);
      
      initializeApp({
        credential: cert(serviceAccount),
      });

      return { success: true, error: null };
    } catch (initError) {
      // This will give us a specific parsing error or initialization error.
      return { success: false, error: `Firebase init failed: ${initError.message}` };
    }
  }
}

serve(async (req) => {
  const firebaseInit = initializeFirebase();
  if (!firebaseInit.success) {
    return new Response(`Error: ${firebaseInit.error}`, { status: 500 });
  }

  try {
    const serviceRoleKey = Deno.env.get("POWERLINK_SERVICE_ROLE_KEY");
    if (!serviceRoleKey) {
      return new Response("Error: POWERLINK_SERVICE_ROLE_KEY is not available.", { status: 500 });
    }

    const supabaseClient = createClient(Deno.env.get("SUPABASE_URL")!, serviceRoleKey);
    const { record: newMessage } = await req.json();
    const { conversation_id, sender_id, body } = newMessage;

    // --- OPTIMIZATION: Run initial queries in parallel ---
    const [participantsRes, convRes] = await Promise.all([
      supabaseClient.from("conversation_participants").select("user_id").eq("conversation_id", conversation_id),
      supabaseClient.from("conversations").select("is_group, title").eq("id", conversation_id).single(),
    ]);

    if (participantsRes.error) throw participantsRes.error;
    if (convRes.error) throw convRes.error;

    const recipientIds = participantsRes.data.map((p) => p.user_id).filter((id) => id !== sender_id);
    if (recipientIds.length === 0) {
      return new Response("ok");
    }

    // --- OPTIMIZATION: Fetch all tokens in parallel ---
    const [employeeTokensRes, managerTokensRes] = await Promise.all([
      supabaseClient.from("employees").select("fcm_token").in("auth_user_id", recipientIds).not("fcm_token", "is", null),
      supabaseClient.from("managers").select("fcm_token").in("auth_user_id", recipientIds).not("fcm_token", "is", null),
    ]);

    if (employeeTokensRes.error) throw employeeTokensRes.error;
    if (managerTokensRes.error) throw managerTokensRes.error;

    const allTokens = [
      ...(employeeTokensRes.data?.map((t) => t.fcm_token) || []),
      ...(managerTokensRes.data?.map((t) => t.fcm_token) || []),
    ];
    const uniqueTokens = [...new Set(allTokens)].filter(Boolean);

    if (uniqueTokens.length === 0) {
      return new Response("ok");
    }

    // --- Title Logic (already efficient) ---
    let title = "New Message";
    const convData = convRes.data;
    if (convData?.is_group) {
      title = convData.title || "Group Message";
    } else {
      // This part is still sequential but less critical than the parallel queries above.
      const { data: senderProfile } = await supabaseClient.from("employees").select("first_name, last_name").eq("auth_user_id", sender_id).single();
      if (senderProfile) {
        title = `${senderProfile.first_name} ${senderProfile.last_name}`;
      } else {
        const { data: managerProfile } = await supabaseClient.from("managers").select("first_name, last_name").eq("auth_user_id", sender_id).single();
        if (managerProfile) {
          title = `${managerProfile.first_name} ${managerProfile.last_name}`;
        }
      }
    }

    const messagePayload = {
      notification: { title, body },
      tokens: uniqueTokens,
    };

    await getMessaging().sendEachForMulticast(messagePayload);

    return new Response("ok");
  } catch (error) {
    // Log the detailed error to the console for better debugging
    console.error("Function Error:", error);
    return new Response(`Error: ${error.message}`, { status: 500 });
  }
});
