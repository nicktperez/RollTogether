import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) return json({ error: "Server is missing Supabase admin configuration" }, 500);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "Missing Authorization header" }, 401);

  const admin = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const { data: userData, error: userError } = await admin.auth.getUser(authHeader.replace("Bearer ", ""));
  if (userError || !userData.user) return json({ error: "Invalid session" }, 401);

  const body = await req.json().catch(() => ({}));
  const groupListingID = body.group_listing_id;
  const partyListingID = body.party_listing_id;
  const score = Math.max(0, Math.min(100, Number(body.score ?? 0)));
  if (!groupListingID || !partyListingID) return json({ error: "group_listing_id and party_listing_id are required" }, 400);

  const { data: group, error: groupError } = await admin
    .from("listings")
    .select("id,owner_user_id,listing_type,is_active,moderation_status")
    .eq("id", groupListingID)
    .eq("listing_type", "group")
    .single();
  if (groupError || !group || !group.is_active || group.moderation_status === "removed") return json({ error: "Active group listing is required" }, 400);

  const { data: party, error: partyError } = await admin
    .from("listings")
    .select("id,owner_user_id,listing_type,is_active,moderation_status")
    .eq("id", partyListingID)
    .eq("listing_type", "party")
    .single();
  if (partyError || !party || !party.is_active || party.moderation_status === "removed") return json({ error: "Active party listing is required" }, 400);

  const userID = userData.user.id;
  if (group.owner_user_id !== userID && party.owner_user_id !== userID) {
    return json({ error: "Only listing owners can create this match" }, 403);
  }

  const { data: match, error: matchError } = await admin
    .from("matches")
    .upsert({
      group_listing_id: groupListingID,
      party_listing_id: partyListingID,
      group_owner_user_id: group.owner_user_id,
      party_owner_user_id: party.owner_user_id,
      score,
      initiated_by: userID,
      status: "active",
    }, { onConflict: "group_listing_id,party_listing_id" })
    .select("id")
    .single();
  if (matchError || !match) return json({ error: matchError?.message ?? "Unable to create match" }, 500);

  const { data: thread, error: threadError } = await admin
    .from("message_threads")
    .upsert({ match_id: match.id, last_message_preview: "Connection opened." }, { onConflict: "match_id" })
    .select("id")
    .single();
  if (threadError || !thread) return json({ error: threadError?.message ?? "Unable to create thread" }, 500);

  return json({ match_id: match.id, thread_id: thread.id });
});
