import { isValidSession } from "../../../functions/_lib/session.js";

const json = (body, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { "content-type": "application/json; charset=utf-8" }
});

const guard = async (request, env) => isValidSession(request, env.ADMIN_SECRET);

export async function onRequestGet({ request, env }) {
  if (!(await guard(request, env))) return json({ ok: false, code: "unauthorized" }, 401);
  if (!env.DB) return json({ ok: false, code: "database_not_configured" }, 503);
  const url = new URL(request.url);
  const limit = Math.min(Math.max(Number(url.searchParams.get("limit") || 100), 1), 200);
  const status = url.searchParams.get("status");
  const result = status
    ? await env.DB.prepare("SELECT id, name, email, market, buyer, message, created_at, status FROM inquiries WHERE status = ? ORDER BY created_at DESC LIMIT ?").bind(status, limit).all()
    : await env.DB.prepare("SELECT id, name, email, market, buyer, message, created_at, status FROM inquiries ORDER BY created_at DESC LIMIT ?").bind(limit).all();
  return json({ ok: true, inquiries: result.results || [] });
}

export async function onRequestPatch({ request, env }) {
  if (!(await guard(request, env))) return json({ ok: false, code: "unauthorized" }, 401);
  if (!env.DB) return json({ ok: false, code: "database_not_configured" }, 503);
  let data;
  try { data = await request.json(); } catch { return json({ ok: false, code: "invalid_json" }, 400); }
  const id = Number(data.id);
  const allowed = ["new", "contacted", "qualified", "closed"];
  if (!Number.isInteger(id) || !allowed.includes(data.status)) return json({ ok: false, code: "invalid_update" }, 422);
  await env.DB.prepare("UPDATE inquiries SET status = ? WHERE id = ?").bind(data.status, id).run();
  return json({ ok: true });
}

