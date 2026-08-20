const json = (body, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { "content-type": "application/json; charset=utf-8" }
});

export async function onRequestPost({ request, env }) {
  if (!env.DB) return json({ ok: false, code: "database_not_configured" }, 503);

  let data;
  try { data = await request.json(); } catch { return json({ ok: false, code: "invalid_json" }, 400); }
  const fields = ["name", "email", "market", "buyer", "message"];
  if (fields.some((field) => typeof data[field] !== "string" || !data[field].trim())) {
    return json({ ok: false, code: "missing_field" }, 422);
  }
  if (!/^\S+@\S+\.\S+$/.test(data.email.trim())) return json({ ok: false, code: "invalid_email" }, 422);
  if (data.message.trim().length > 5000) return json({ ok: false, code: "message_too_long" }, 422);

  await env.DB.prepare(
    "INSERT INTO inquiries (name, email, market, buyer, message) VALUES (?, ?, ?, ?, ?)"
  ).bind(data.name.trim(), data.email.trim(), data.market.trim(), data.buyer.trim(), data.message.trim()).run();
  return json({ ok: true });
}

