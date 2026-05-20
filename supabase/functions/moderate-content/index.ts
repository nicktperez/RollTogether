import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
const blockedTerms = ["kill yourself", "kys", "doxx", "doxxing", "nazi"];
const riskyTerms = ["nsfw", "18+", "explicit"];

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const body = await req.json().catch(() => ({}));
  const text = Array.isArray(body.values) ? body.values.join(" ") : String(body.text ?? "");
  const openAIKey = Deno.env.get("OPENAI_API_KEY");

  if (openAIKey) {
    const response = await fetch("https://api.openai.com/v1/moderations", {
      method: "POST",
      headers: { "Authorization": `Bearer ${openAIKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({ model: "omni-moderation-latest", input: text }),
    });
    if (!response.ok) return json({ error: await response.text() }, 502);
    const result = await response.json();
    const flagged = Boolean(result?.results?.[0]?.flagged);
    return json({ status: flagged ? "flagged" : "approved", reason: flagged ? "OpenAI moderation flagged this content." : "" });
  }

  const lower = text.toLowerCase();
  const blocked = blockedTerms.find((term) => lower.includes(term));
  if (blocked) return json({ status: "removed", reason: `Blocked unsafe term: ${blocked}` });
  const risky = riskyTerms.find((term) => lower.includes(term));
  if (risky) return json({ status: "flagged", reason: `Needs review for: ${risky}` });
  return json({ status: "approved", reason: "" });
});
