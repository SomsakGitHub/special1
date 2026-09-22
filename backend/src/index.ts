import { neon } from "@neondatabase/serverless";

export interface Env {
  DATABASE_URL?: string;
  ENVIRONMENT?: string;
}

let cachedSql: ReturnType<typeof neon> | null = null;

function getSql(env: Env) {
  if (cachedSql) return cachedSql;
  if (!env.DATABASE_URL) {
    throw new Error("DATABASE_URL is not configured");
  }
  cachedSql = neon(env.DATABASE_URL, { fetchOptions: { cache: "no-store" } });
  return cachedSql;
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "access-control-allow-origin": "*",
      "cache-control": "no-store",
    },
  });
}

function notFound(message = "Not found"): Response {
  return json({ error: message }, 404);
}

function serverError(message: string): Response {
  return json({ error: message }, 500);
}

function html(content: string): Response {
  return new Response(content, {
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "public, max-age=3600",
    },
  });
}

type Row = Record<string, any>;

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const { pathname } = url;
    const method = request.method.toUpperCase();

    if (method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "access-control-allow-origin": "*",
          "access-control-allow-methods": "GET,OPTIONS",
          "access-control-allow-headers": "content-type",
        },
      });
    }

    if (pathname === "/" || pathname === "/health") {
      try {
        const sql = getSql(env);
        const rows = (await sql`SELECT 1 AS ok`) as Row[];
        return json({ ok: true, database: rows[0]?.ok === 1, environment: env.ENVIRONMENT ?? "unknown" });
      } catch (err) {
        return serverError(`Database unreachable: ${(err as Error).message}`);
      }
    }

    if (pathname === "/api/home" && method === "GET") {
      try {
        const sql = getSql(env);
        const rows = (await sql`
          SELECT club, handicap
          FROM home
          WHERE id = 1
        `) as Row[];
        const row = rows[0] ?? {};
        return json({
          club: row.club ?? null,
          handicap: row.handicap ?? null,
        });
      } catch (err) {
        return serverError(`Query failed: ${(err as Error).message}`);
      }
    }

    if (pathname === "/privacy" && method === "GET") {
      return html(`
<!doctype html><html lang="th"><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Privacy Policy — special1</title>
<body style="font-family:-apple-system,system-ui;max-width:640px;margin:40px auto;padding:0 16px;line-height:1.6;color:#222">
<h1>Privacy Policy</h1>
<p>Special1 does not collect, store, or share any personal data. The app only displays public football information loaded from our own server. No third-party analytics or advertising SDKs are used.</p>
<p><em>Last updated: September 23, 2026</em></p>
</body></html>`);
    }

    if (pathname === "/support" && method === "GET") {
      return html(`
<!doctype html><html lang="th"><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Support — special1</title>
<body style="font-family:-apple-system,system-ui;max-width:640px;margin:40px auto;padding:0 16px;line-height:1.6;color:#222">
<h1>Support</h1>
<p>If you have questions about Special1, please contact the developer by providing your feedback through the App Store review or by reaching out via GitHub:
<a href="https://github.com/SomsakGitHub/special1">github.com/SomsakGitHub/special1</a>.</p>
</body></html>`);
    }

    return notFound(`No route for ${method} ${pathname}`);
  },
};