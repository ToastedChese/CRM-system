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
    // Return the detailed error message to the trigger.
    return new Response(`Error: ${firebaseInit.error}`, { status: 500 });
  }

  try {
    // Use a custom environment variable for the service role key to avoid conflicts.
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("POWERLINK_SERVICE_ROLE_KEY")!
    );

    const { record: newMessage } = await req.json();

    const { conversation_id, sender_id, body } = newMessage;

    const { data: participants, error: partsError } = await supabaseClient
      .from("conversation_participants")
      .select("user_id")
      .eq("conversation_id", conversation_id);

    if (partsError) throw partsError;

    const recipientIds = participants
      .map((p) => p.user_id)
      .filter((id) => id !== sender_id);

    if (recipientIds.length === 0) {
      return new Response("ok");
    }

    const { data: employeeTokens } = await supabaseClient
      .from("employees")
      .select("fcm_token")
      .in("auth_user_id", recipientIds)
      .not("fcm_token", "is", null);

    const { data: managerTokens } = await supabaseClient
      .from("managers")
      .select("fcm_token")
      .in("auth_user_id", recipientIds)
      .not("fcm_token", "is", null);

    const allTokens = [
      ...(employeeTokens?.map((t) => t.fcm_token) || []),
      ...(managerTokens?.map((t) => t.fcm_token) || []),
    ];
    const uniqueTokens = [...new Set(allTokens)].filter(Boolean);

    if (uniqueTokens.length === 0) {
      return new Response("ok");
    }

    const { data: convData } = await supabaseClient
      .from("conversations")
      .select("is_group, title")
      .eq("id", conversation_id)
      .single();

    let title = "New Message";
    if (convData?.is_group) {
      title = convData.title || "Group Message";
    } else {
      const { data: senderProfile } = await supabaseClient
        .from("employees")
        .select("first_name, last_name")
        .eq("auth_user_id", sender_id)
        .single();
      if (senderProfile) {
        title = `${senderProfile.first_name} ${senderProfile.last_name}`;
      } else {
        const { data: managerProfile } = await supabaseClient
            .from("managers")
            .select("first_name, last_name")
            .eq("auth_user_id", sender_id)
            .single();
        if (managerProfile) {
            title = `${managerProfile.first_name} ${managerProfile.last_name}`;
        }
      }
    }

    const messagePayload = {
      notification: { title, body },
      tokens: uniqueTokens,
    };

    const response = await getMessaging().sendEachForMulticast(messagePayload);
    
    if (response.failureCount > 0) {
        response.responses.forEach(resp => {
            if (!resp.success) {
                console.error(`Failed to send to a token: ${resp.error}`);
            }
        });
    }

    return new Response("ok");
  } catch (error) {
    return new Response(`Error: ${error.message}`, { status: 500 });
  }
});
