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

    return notFound(`No route for ${method} ${pathname}`);
  },
};