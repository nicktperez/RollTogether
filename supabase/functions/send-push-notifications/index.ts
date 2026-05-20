import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { SignJWT, importPKCS8 } from "npm:jose@5.9.6";

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

type NotificationRow = {
  id: string;
  user_id: string;
  title: string;
  body: string;
  payload: Record<string, unknown>;
};

type PushTokenRow = {
  token: string;
  environment: string;
};

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) return json({ error: "Server is missing Supabase admin configuration" }, 500);

  const dryRun = await req.json().then((value) => Boolean(value?.dryRun)).catch(() => false);
  const admin = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const { data: pending, error } = await admin
    .from("notifications")
    .select("id,user_id,title,body,payload")
    .is("delivered_at", null)
    .order("created_at", { ascending: true })
    .limit(50);
  if (error) return json({ error: error.message }, 500);

  const config = await loadApnsConfig();
  if (!config.ready || dryRun) {
    return json({ queued: pending?.length ?? 0, delivered: 0, dryRun, needsApnsConfiguration: !config.ready, missing: config.missing });
  }

  let delivered = 0;
  const failures: Array<{ notificationID: string; error: string }> = [];

  for (const notification of (pending ?? []) as NotificationRow[]) {
    const { data: tokens, error: tokenError } = await admin
      .from("push_tokens")
      .select("token,environment")
      .eq("user_id", notification.user_id);
    if (tokenError) {
      failures.push({ notificationID: notification.id, error: tokenError.message });
      continue;
    }

    for (const pushToken of (tokens ?? []) as PushTokenRow[]) {
      const response = await sendApns(config, pushToken, notification);
      if (response.ok) {
        delivered += 1;
      } else {
        failures.push({ notificationID: notification.id, error: await response.text() });
      }
    }

    if ((tokens?.length ?? 0) > 0) {
      await admin.from("notifications").update({ delivered_at: new Date().toISOString() }).eq("id", notification.id);
    }
  }

  return json({ queued: pending?.length ?? 0, delivered, failures });
});

async function loadApnsConfig() {
  const keyID = Deno.env.get("APNS_KEY_ID");
  const teamID = Deno.env.get("APNS_TEAM_ID");
  const bundleID = Deno.env.get("APNS_BUNDLE_ID");
  const privateKey = Deno.env.get("APNS_PRIVATE_KEY")?.replace(/\\n/g, "\n");
  const useSandbox = Deno.env.get("APNS_USE_SANDBOX") !== "false";
  const missing = [
    ["APNS_KEY_ID", keyID],
    ["APNS_TEAM_ID", teamID],
    ["APNS_BUNDLE_ID", bundleID],
    ["APNS_PRIVATE_KEY", privateKey],
  ].filter(([, value]) => !value).map(([name]) => name);

  if (missing.length > 0 || !keyID || !teamID || !bundleID || !privateKey) {
    return { ready: false, missing } as const;
  }

  const key = await importPKCS8(privateKey, "ES256");
  const jwt = await new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: keyID })
    .setIssuer(teamID)
    .setIssuedAt()
    .setExpirationTime("50m")
    .sign(key);
  return { ready: true, keyID, teamID, bundleID, privateKey, useSandbox, jwt } as const;
}

async function sendApns(config: Awaited<ReturnType<typeof loadApnsConfig>> & { ready: true }, pushToken: PushTokenRow, notification: NotificationRow) {
  const host = config.useSandbox || pushToken.environment === "development" ? "https://api.sandbox.push.apple.com" : "https://api.push.apple.com";
  return await fetch(`${host}/3/device/${pushToken.token}`, {
    method: "POST",
    headers: {
      "authorization": `bearer ${config.jwt}`,
      "apns-topic": config.bundleID,
      "apns-push-type": "alert",
      "apns-priority": "10",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      aps: {
        alert: { title: notification.title, body: notification.body },
        sound: "default",
      },
      ...notification.payload,
    }),
  });
}
