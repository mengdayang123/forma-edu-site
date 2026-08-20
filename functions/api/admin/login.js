import { createSession, sessionCookie } from "../../../functions/_lib/session.js";

const json = (body, status = 200, headers = {}) => new Response(JSON.stringify(body), {
  status,
  headers: { "content-type": "application/json; charset=utf-8", ...headers }
});

export async function onRequestPost({ request, env }) {
  if (!env.ADMIN_PASSWORD || !env.ADMIN_SECRET) return json({ ok: false, code: "admin_not_configured" }, 503);
  let data;
  try { data = await request.json(); } catch { return json({ ok: false, code: "invalid_json" }, 400); }
  if (typeof data.password !== "string" || data.password.length < 1 || data.password !== env.ADMIN_PASSWORD) {
    return json({ ok: false, code: "invalid_password" }, 401);
  }
  const token = await createSession(env.ADMIN_SECRET);
  return json({ ok: true }, 200, { "set-cookie": sessionCookie(token) });
}

