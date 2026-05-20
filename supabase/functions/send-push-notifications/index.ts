import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

Deno.serve(async (_req: Request) => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) return json({ error: "Server is missing Supabase admin configuration" }, 500);

  const admin = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const { data: pending, error } = await admin
    .from("notifications")
    .select("id,user_id,title,body,payload")
    .is("delivered_at", null)
    .limit(50);
  if (error) return json({ error: error.message }, 500);

  return json({ queued: pending?.length ?? 0, delivered: 0, needsApnsConfiguration: true });
});
