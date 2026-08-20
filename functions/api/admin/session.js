import { isValidSession } from "../../../functions/_lib/session.js";

export async function onRequestGet({ request, env }) {
  const authenticated = await isValidSession(request, env.ADMIN_SECRET);
  return new Response(JSON.stringify({ authenticated }), {
    status: 200,
    headers: { "content-type": "application/json; charset=utf-8" }
  });
}

