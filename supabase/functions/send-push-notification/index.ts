import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Get the FCM Server Key you stored in Supabase secrets
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY");

serve(async (req) => {
  try {
    // Create a Supabase client with the user's authorization
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    // Extract the new message details from the trigger's payload
    const { record: newMessage } = await req.json();
    const senderId = newMessage.sender_id;
    const conversationId = newMessage.conversation_id;
    const messageBody = newMessage.body;

    // Find all participants in the conversation.
    // NOTE: This assumes you have a table named 'conversation_participants'
    // that links users to conversations. If your table has a different name,
    // you must change it here.
    const { data: participants, error: partsError } = await supabaseClient
      .from("conversation_participants")
      .select("user_id")
      .eq("conversation_id", conversationId);

    if (partsError) throw partsError;

    // Find the recipients by filtering out the original sender
    const recipientIds = participants
      .map((p) => p.user_id)
      .filter((id) => id !== senderId);

    if (recipientIds.length === 0) {
      console.log("No other participants in conversation to notify.");
      return new Response("No recipients to notify", { status: 200 });
    }

    // Get the FCM tokens for all recipients from both the employees and managers tables
    const { data: employeeTokens, error: empError } = await supabaseClient
      .from("employees")
      .select("fcm_token")
      .in("id", recipientIds)
      .not("fcm_token", "is", null);

    const { data: managerTokens, error: manError } = await supabaseClient
      .from("managers")
      .select("fcm_token")
      .in("id", recipientIds)
      .not("fcm_token", "is", null);

    if (empError) throw empError;
    if (manError) throw manError;

    // Combine all the found tokens into a single list
    const allTokens = [
      ...employeeTokens.map((t) => t.fcm_token),
      ...managerTokens.map((t) => t.fcm_token),
    ].filter(Boolean); // .filter(Boolean) removes any null/undefined entries

    if (allTokens.length === 0) {
        console.log("No valid FCM tokens found for any recipients.");
        return new Response("No valid FCM tokens found for recipients", { status: 200 });
    }

    // Prepare the notification payload to send to Firebase
    const notificationPayload = {
      registration_ids: allTokens, // Use registration_ids for multiple tokens
      notification: {
        title: "New Message", // You can customize this later
        body: messageBody,
        sound: "default",
      },
      // You can also add a 'data' payload for handling taps in the app
      data: {
        "conversation_id": conversationId.toString(),
      }
    };

    // Send the request to Firebase Cloud Messaging
    const fcmResponse = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `key=${FCM_SERVER_KEY}`,
      },
      body: JSON.stringify(notificationPayload),
    });

    if (!fcmResponse.ok) {
        const errorBody = await fcmResponse.text();
        throw new Error(`FCM request failed: ${fcmResponse.status} ${errorBody}`);
    }

    console.log("Successfully sent push notification to", allTokens.length, "devices.");
    return new Response("Notification sent successfully", { status: 200 });

  } catch (error) {
    console.error("Error sending notification:", error);
    return new Response(
      `Internal Server Error: ${error.message}`, { status: 500 });
  }
});