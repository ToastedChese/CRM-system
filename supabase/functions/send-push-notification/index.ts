import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.42.0";
import { initializeApp, getApp, cert } from "npm:firebase-admin@12.0.0/app";
import { getMessaging } from "npm:firebase-admin@12.0.0/messaging";

function initializeFirebase() {
  try {
    getApp();
    return {
      success: true,
      error: null
    };
  } catch (e) {
    try {
      const serviceAccountString = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
      if (!serviceAccountString || serviceAccountString.trim() === "") {
        return {
          success: false,
          error: "FCM_SERVICE_ACCOUNT_JSON secret is missing or empty."
        };
      }
      const serviceAccount = JSON.parse(serviceAccountString);
      initializeApp({
        credential: cert(serviceAccount)
      });
      return {
        success: true,
        error: null
      };
    } catch (initError) {
      return {
        success: false,
        error: `Firebase init failed: ${initError.message}`
      };
    }
  }
}

serve(async (req) => {
  const incomingAuth = req.headers.get("authorization");
  console.info("incoming authorization present:", !!incomingAuth);
  if (incomingAuth) {
    console.info("auth startsWith:", incomingAuth.slice(0, 40));
  }

  // --- BEGIN: JWT validation (early) ---
  // Expect Authorization: Bearer <jwt>
  const authHeader = req.headers.get("authorization") || "";
  let token: string | null = null;
  let jwtPayLoad: Record<string, any> | null = null;
  let role: string | null = null;

  if (authHeader.startsWith("Bearer ")) {
    token = authHeader.split(" ")[1];
    const parts = token.split(".");
    if (parts.length !== 3) {
      return new Response(
        JSON.stringify({ error: "Invalid JWT structure" }),
        {
          status: 401,
          headers: { "Content-Type": "application/json" }
        }
      );
    }
    try {
      jwtPayLoad = JSON.parse(
        atob(parts[1].replace(/-/g, "+").replace(/_/g, "/"))
      );
    } catch (e) {
      return new Response(
        JSON.stringify({ error: "Invalid JWT payload" }),
        {
          status: 401,
          headers: { "Content-Type": "application/json" }
        }
      );
    }

    // --- DEBUGGING PATCH: log claim keys + trigger header presence (safe) ---
    // Use unique debug variable names to avoid conflicts
    const __dbg_claimKeys = Array.isArray(Object.keys(jwtPayLoad))
      ? Object.keys(jwtPayLoad)
      : [];
    console.info("jwt claim keys:", __dbg_claimKeys); // safe: keys only

    // Detect common role locations (do not log the role value)
    role =
      jwtPayLoad["role"] ||
      jwtPayLoad["https://hasura.io/jwt/claims"]?.["x-hasura-role"] ||
      jwtPayLoad["app_metadata"]?.["role"];

    console.info("role found:", !!role);

    // Inspect incoming trigger headers (presence + simple match) using unique names
    const __dbg_incomingTriggerHeader =
      req.headers.get("x-trigger-secret") ||
      req.headers.get("x-supabase-webhook-secret") ||
      null;
    const __dbg_triggerSecretConfigured = !!Deno.env.get("TRIGGER_SECRET");
    const __dbg_triggerMatched =
      __dbg_triggerSecretConfigured &&
      __dbg_incomingTriggerHeader === Deno.env.get("TRIGGER_SECRET");

    console.info(
      "incoming trigger header present:",
      !!__dbg_incomingTriggerHeader
    );
    console.info("trigger secret configured:", __dbg_triggerSecretConfigured);
    console.info(
      "trigger header matches configured secret:",
      __dbg_triggerMatched
    );

    // --- Trigger-secret fallback: allow requests with no role if correct secret provided ---
    const incomingSecretHeader =
      req.headers.get("x-trigger-secret") ||
      req.headers.get("x-supabase-webhook-secret");
    const triggerSecretEarly = Deno.env.get("TRIGGER_SECRET"); // ensure this is set in secrets
    const triggerValidated =
      triggerSecretEarly &&
      incomingSecretHeader &&
      incomingSecretHeader === triggerSecretEarly;

    if (!role && triggerValidated) {
      role = "webhook";
      console.info(
        "authorization: role missing — validated via trigger secret (fallback)"
      );
    }

    // If an Authorization header was sent but contains no role and no valid trigger secret, reject
    if (!role) {
      return new Response(
        JSON.stringify({ error: "Insufficient role" }),
        {
          status: 403,
          headers: { "Content-Type": "application/json" }
        }
      );
    }

    // If you require a specific role, enforce it (optional). Allow webhook as well
    if (role !== "authenticated" && role !== "webhook") {
      return new Response(
        JSON.stringify({ error: "Insufficient role" }),
        {
          status: 403,
          headers: { "Content-Type": "application/json" }
        }
      );
    }
  } else {
    // No Authorization header — assume webhook invocation. Continue but require trigger secret below.
    // (If you want stricter behavior, set STRICT_TRIGGER_VALIDATION=true to force header presence.)
  }
  // --- END: JWT validation ---

  // Compatibility / strict trigger secret validation
  const HEADER_NAME = "x-trigger-secret";
  const triggerSecret = Deno.env.get("TRIGGER_SECRET") ?? "";
  const strictMode =
    (Deno.env.get("STRICT_TRIGGER_VALIDATION") ?? "false").toLowerCase() ===
    "true";
  const incomingSecret =
    req.headers.get(HEADER_NAME) ??
    req.headers.get(HEADER_NAME.toLowerCase()) ??
    null;
  if (!triggerSecret) {
    // If no secret is configured, warn and continue (can't validate)
    console.warn("TRIGGER_SECRET not set in environment — validation disabled.");
  } else {
    if (!incomingSecret) {
      const msg = "missing trigger header";
      if (strictMode) {
        console.warn(`${msg} — STRICT mode enabled; rejecting request.`);
        return new Response(
          JSON.stringify({ error: "missing trigger secret" }),
          {
            status: 401,
            headers: { "Content-Type": "application/json" }
          }
        );
      } else {
        console.warn(`${msg} — compatibility mode: allowing request for now.`);
      }
    } else if (incomingSecret !== triggerSecret) {
      const msg = "invalid trigger secret";
      if (strictMode) {
        console.warn(`${msg} — STRICT mode enabled; rejecting request.`);
        return new Response(
          JSON.stringify({ error: "invalid trigger secret" }),
          {
            status: 401,
            headers: { "Content-Type": "application/json" }
          }
        );
      } else {
        console.warn(`${msg} — compatibility mode: allowing request for now.`);
      }
    } else {
      console.info("trigger secret validated successfully.");
    }
  }

  // Init Firebase
  const firebaseInit = initializeFirebase();
  if (!firebaseInit.success) {
    console.error("Firebase init error:", firebaseInit.error);
    return new Response(JSON.stringify({ error: firebaseInit.error }), {
      status: 500
    });
  }

  // Ensure service role key exists
  const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
  const SUPABASE_SERVICE_ROLE =
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
    Deno.env.get("SUPABASE_SERVICE_ROLE");
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE) {
    console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    return new Response(JSON.stringify({ error: "Server misconfiguration" }), {
      status: 500
    });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE, {
    auth: {
      persistSession: false
    }
  });

  try {
    const payload = await req.json();
    const newMessage = payload.record;
    if (!newMessage) {
      return new Response(
        JSON.stringify({ error: "Bad request: missing record" }),
        { status: 400 }
      );
    }
    const { conversation_id, sender_id, body } = newMessage;

    // Fetch participants
    const { data: participants, error: partsError } = await supabase
      .from("conversation_participants")
      .select("user_id")
      .eq("conversation_id", conversation_id);
    if (partsError) throw partsError;
    const recipientIds = (participants || [])
      .map((p: any) => p.user_id)
      .filter((id: any) => id !== sender_id);
    if (!recipientIds.length)
      return new Response(JSON.stringify({ ok: true }), { status: 200 });

    // Fetch tokens (combined in one query if possible)
    const { data: employeeTokens, error: empErr } = await supabase
      .from("employees")
      .select("fcm_token, auth_user_id")
      .in("auth_user_id", recipientIds)
      .not("fcm_token", "is", null);
    if (empErr) throw empErr;

    const { data: managerTokens, error: mgrErr } = await supabase
      .from("managers")
      .select("fcm_token, auth_user_id")
      .in("auth_user_id", recipientIds)
      .not("fcm_token", "is", null);
    if (mgrErr) throw mgrErr;

    const allTokens = [
      ...(employeeTokens?.map((t: any) => t.fcm_token) || []),
      ...(managerTokens?.map((t: any) => t.fcm_token) || [])
    ];
    const uniqueTokens = [...new Set(allTokens)].filter(Boolean);
    if (uniqueTokens.length === 0)
      return new Response(JSON.stringify({ ok: true }), { status: 200 });

    // Determine title
    const { data: convData } = await supabase
      .from("conversations")
      .select("is_group, title")
      .eq("id", conversation_id)
      .single();
    let title = "New Message";
    if (convData?.is_group) {
      title = convData.title || "Group Message";
    } else {
      const { data: senderProfile } = await supabase
        .from("employees")
        .select("first_name, last_name")
        .eq("auth_user_id", sender_id)
        .single();
      if (senderProfile) {
        title = `${senderProfile.first_name} ${senderProfile.last_name}`;
      } else {
        const { data: managerProfile } = await supabase
          .from("managers")
          .select("first_name, last_name")
          .eq("auth_user_id", sender_id)
          .single();
        if (managerProfile)
          title = `${managerProfile.first_name} ${managerProfile.last_name}`;
      }
    }

    const messagePayload = {
      notification: {
        title,
        body
      },
      tokens: uniqueTokens
    };

    const response = await getMessaging().sendEachForMulticast(messagePayload);
    if (response.failureCount > 0) {
      response.responses.forEach((resp: any) => {
        if (!resp.success) {
          console.error("FCM send error:", resp.error);
        }
      });
    }

    return new Response(
      JSON.stringify({
        ok: true,
        successCount: response.successCount,
        failureCount: response.failureCount
      }),
      { status: 200 }
    );
  } catch (err) {
    console.error("Edge function error:", err);
    return new Response(JSON.stringify({ error: err?.message || String(err) }), {
      status: 500
    });
  }
});