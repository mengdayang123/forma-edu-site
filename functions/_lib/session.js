const COOKIE_NAME = "forma_admin";
const MAX_AGE = 60 * 60 * 8;

const base64url = (input) => {
  const bytes = typeof input === "string" ? new TextEncoder().encode(input) : new Uint8Array(input);
  let binary = "";
  bytes.forEach((byte) => { binary += String.fromCharCode(byte); });
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
};

const fromBase64url = (input) => {
  const normalized = input.replace(/-/g, "+").replace(/_/g, "/") + "===".slice((input.length + 3) % 4);
  const binary = atob(normalized);
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
};

const sign = async (value, secret) => {
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  return base64url(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(value)));
};

export const createSession = async (secret) => {
  const payload = base64url(JSON.stringify({ exp: Date.now() + MAX_AGE * 1000 }));
  return `${payload}.${await sign(payload, secret)}`;
};

export const readCookie = (request, name) => {
  const header = request.headers.get("cookie") || "";
  const match = header.split(";").map((item) => item.trim()).find((item) => item.startsWith(`${name}=`));
  return match ? decodeURIComponent(match.slice(name.length + 1)) : "";
};

export const isValidSession = async (request, secret) => {
  if (!secret) return false;
  const token = readCookie(request, COOKIE_NAME);
  const [payload, signature] = token.split(".");
  if (!payload || !signature) return false;
  const expected = await sign(payload, secret);
  if (signature.length !== expected.length) return false;
  const actualBytes = fromBase64url(signature);
  const expectedBytes = fromBase64url(expected);
  let difference = 0;
  for (let index = 0; index < expectedBytes.length; index += 1) difference |= actualBytes[index] ^ expectedBytes[index];
  const validSignature = difference === 0;
  if (!validSignature) return false;
  try { return JSON.parse(new TextDecoder().decode(fromBase64url(payload))).exp > Date.now(); } catch { return false; }
};

export const sessionCookie = (token) => `${COOKIE_NAME}=${encodeURIComponent(token)}; Max-Age=${MAX_AGE}; Path=/; HttpOnly; Secure; SameSite=Strict`;
export const clearSessionCookie = `${COOKIE_NAME}=; Max-Age=0; Path=/; HttpOnly; Secure; SameSite=Strict`;
