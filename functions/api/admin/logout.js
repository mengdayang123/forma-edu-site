import { clearSessionCookie } from "../../../functions/_lib/session.js";

export async function onRequestPost() {
  return new Response(JSON.stringify({ ok: true }), {
    headers: { "content-type": "application/json; charset=utf-8", "set-cookie": clearSessionCookie }
  });
}

