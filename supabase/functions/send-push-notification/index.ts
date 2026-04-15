// Supabase Edge Function: send-push-notification
// Deploy: supabase functions deploy send-push-notification
// Trigger: Database Webhook trên bảng notifications (INSERT)

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { JWT } from "npm:google-auth-library@9";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
// Require the developer to store their Service Account JSON string in Vault or .env
const FIREBASE_SERVICE_ACCOUNT = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");

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

    if (!FIREBASE_SERVICE_ACCOUNT) {
       console.error("Missing FIREBASE_SERVICE_ACCOUNT env var.");
       return new Response("Missing FIREBASE_SERVICE_ACCOUNT config", { status: 500 });
    }

    // Thiết lập xác thực Google OAuth 2.0 bằng JWT.
    const serviceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT);
    const jwtClient = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: ["https://www.googleapis.com/auth/cloud-platform"],
    });

    const tokens = await jwtClient.authorize();
    const accessToken = tokens.access_token;
    const projectId = serviceAccount.project_id;

    if (!accessToken || !projectId) {
      return new Response("Failed to generate Google Access Token", { status: 500 });
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
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
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
