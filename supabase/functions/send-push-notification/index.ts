// Supabase Edge Function: send-push-notification
// Deploy: supabase functions deploy send-push-notification
// Trigger: Database Webhook trên bảng notifications (INSERT)

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY")!;

serve(async (req) => {
  try {
    const body = await req.json();
    // Payload từ Database Webhook (type: INSERT)
    const record = body.record;
    if (!record) {
      return new Response("No record", { status: 400 });
    }

    const { user_id, title, message, type } = record;
    if (!user_id) {
      return new Response("No user_id", { status: 400 });
    }

    // Lấy FCM token của user
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const { data: profile, error } = await supabase
      .from("profiles")
      .select("fcm_token, display_name")
      .eq("id", user_id)
      .single();

    if (error || !profile?.fcm_token) {
      console.log(`No FCM token for user ${user_id}`);
      return new Response("No FCM token", { status: 200 });
    }

    // Gửi push notification qua FCM v1 API
    const fcmPayload = {
      message: {
        token: profile.fcm_token,
        notification: {
          title: title ?? "Thông báo mới",
          body: message ?? "",
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channel_id: type === "new_message" ? "chat_channel" : "default_channel",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
        data: {
          type: type ?? "general",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
    };

    // Gọi FCM HTTP v1 API
    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${Deno.env.get("FIREBASE_PROJECT_ID")}/messages:send`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${FCM_SERVER_KEY}`,
        },
        body: JSON.stringify(fcmPayload),
      }
    );

    const fcmJson = await fcmRes.json();
    console.log("FCM Response:", JSON.stringify(fcmJson));

    return new Response(JSON.stringify({ ok: true, fcm: fcmJson }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (err) {
    console.error("Edge Function error:", err);
    return new Response(String(err), { status: 500 });
  }
});
