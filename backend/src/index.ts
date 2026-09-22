import { neon } from "@neondatabase/serverless";

export interface Env {
  DATABASE_URL?: string;
  ADMIN_TOKEN?: string;
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

function badRequest(message: string): Response {
  return json({ error: message }, 400);
}

function notFound(message = "Not found"): Response {
  return json({ error: message }, 404);
}

function unauthorized(message = "Unauthorized"): Response {
  return json({ error: message }, 401);
}

function serverError(message: string): Response {
  return json({ error: message }, 500);
}

type Row = Record<string, any>;

function buildWhere(filters: { finished?: boolean; upcoming?: boolean }) {
  const clauses: string[] = [];

  if (filters.finished) {
    clauses.push(`status = 'finished'`);
  }
  if (filters.upcoming) {
    clauses.push(`status != 'finished'`);
  }

  return {
    where: clauses.length ? `WHERE ${clauses.join(" AND ")}` : "",
  };
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const { pathname } = url;
    const method = request.method.toUpperCase();

    if (method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "access-control-allow-origin": "*",
          "access-control-allow-methods": "GET,POST,OPTIONS",
          "access-control-allow-headers": "content-type, authorization",
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
          SELECT
            (SELECT name FROM teams WHERE short_name = 'MUN') AS "club",
            (SELECT handicap
             FROM matches m
             JOIN teams ht ON ht.id = m.home_team_id
             JOIN teams at ON at.id = m.away_team_id
             WHERE (ht.short_name = 'MUN' OR at.short_name = 'MUN')
               AND m.status != 'finished'
               AND m.handicap IS NOT NULL
             ORDER BY m.matchday, m.kickoff_at
             LIMIT 1) AS "handicap"
        `) as Row[];
        const row = rows[0] ?? {};
        return json({ club: row.club ?? "Manchester United", handicap: row.handicap ?? null });
      } catch (err) {
        return serverError(`Query failed: ${(err as Error).message}`);
      }
    }

    if (pathname === "/api/teams" && method === "GET") {
      try {
        const sql = getSql(env);
        const rows = await sql`
          SELECT id, name, short_name, city, primary_color AS "primaryColor", logo_url AS "logoUrl"
          FROM teams
          ORDER BY name
        `;
        return json({ teams: rows });
      } catch (err) {
        return serverError(`Query failed: ${(err as Error).message}`);
      }
    }

    if (pathname === "/api/matches" && method === "GET") {
      const finished = url.searchParams.get("finished") === "true";
      const upcoming = url.searchParams.get("upcoming") === "true";
      const { where } = buildWhere({ finished, upcoming });

      try {
        const sql = getSql(env);
        const queryText = `
          SELECT
            m.id,
            m.matchday,
            m.kickoff_at AS "kickoffAt",
            m.status,
            m.home_goals AS "homeGoals",
            m.away_goals AS "awayGoals",
            m.odds_home AS "oddsHome",
            m.odds_draw AS "oddsDraw",
            m.odds_away AS "oddsAway",
            jsonb_build_object(
              'id', ht.id,
              'name', ht.name,
              'shortName', ht.short_name,
              'logoUrl', ht.logo_url
            ) AS "homeTeam",
            jsonb_build_object(
              'id', at.id,
              'name', at.name,
              'shortName', at.short_name,
              'logoUrl', at.logo_url
            ) AS "awayTeam"
          FROM matches m
          JOIN teams ht ON ht.id = m.home_team_id
          JOIN teams at ON at.id = m.away_team_id
          ${where}
          ORDER BY m.matchday, m.kickoff_at
        `;
        const rows = (await sql.query(queryText)) as Row[];
        return json({ matches: rows });
      } catch (err) {
        return serverError(`Query failed: ${(err as Error).message}`);
      }
    }

    if (pathname === "/api/matches" && method === "POST") {
      if (!env.ADMIN_TOKEN || request.headers.get("authorization") !== `Bearer ${env.ADMIN_TOKEN}`) {
        return unauthorized();
      }

      let body: {
        matchday?: number;
        kickoffAt?: string;
        homeTeamId?: number;
        awayTeamId?: number;
        homeGoals?: number | null;
        awayGoals?: number | null;
        status?: "scheduled" | "finished" | "postponed";
        oddsHome?: number;
        oddsDraw?: number;
        oddsAway?: number;
      };
      try {
        body = await request.json();
      } catch {
        return badRequest("Invalid JSON body");
      }

      if (!body.matchday || !body.homeTeamId || !body.awayTeamId) {
        return badRequest("matchday, homeTeamId and awayTeamId are required");
      }
      if (body.homeTeamId === body.awayTeamId) {
        return badRequest("homeTeamId and awayTeamId must differ");
      }

      try {
        const sql = getSql(env);
        const [row] = (await sql`
          INSERT INTO matches (
            matchday, kickoff_at, home_team_id, away_team_id,
            home_goals, away_goals, status, odds_home, odds_draw, odds_away
          ) VALUES (
            ${body.matchday},
            ${body.kickoffAt ?? null},
            ${body.homeTeamId},
            ${body.awayTeamId},
            ${body.homeGoals ?? null},
            ${body.awayGoals ?? null},
            ${body.status ?? "scheduled"},
            ${body.oddsHome ?? null},
            ${body.oddsDraw ?? null},
            ${body.oddsAway ?? null}
          )
          RETURNING id, matchday, status
        `) as Row[];
        return json({ match: row }, 201);
      } catch (err) {
        return serverError(`Insert failed: ${(err as Error).message}`);
      }
    }

    const matchDetail = pathname.match(/^\/api\/matches\/(\d+)$/);
    if (matchDetail && method === "GET") {
const id = Number(matchDetail[1]);
        try {
          const sql = getSql(env);
          const rows = (await sql`
            SELECT
              m.id, m.matchday, m.kickoff_at AS "kickoffAt", m.status,
              m.home_goals AS "homeGoals", m.away_goals AS "awayGoals",
              m.odds_home AS "oddsHome", m.odds_draw AS "oddsDraw", m.odds_away AS "oddsAway",
              jsonb_build_object('id', ht.id, 'name', ht.name, 'shortName', ht.short_name, 'logoUrl', ht.logo_url) AS "homeTeam",
              jsonb_build_object('id', at.id, 'name', at.name, 'shortName', at.short_name, 'logoUrl', at.logo_url) AS "awayTeam"
            FROM matches m
            JOIN teams ht ON ht.id = m.home_team_id
            JOIN teams at ON at.id = m.away_team_id
            WHERE m.id = ${id}
          `) as Row[];
          if (rows.length === 0) return notFound("Match not found");
          return json({ match: rows[0] });
      } catch (err) {
        return serverError(`Query failed: ${(err as Error).message}`);
      }
    }

    if (pathname === "/api/standings" && method === "GET") {
      try {
        const sql = getSql(env);
        const rows = (await sql`
          SELECT *
          FROM (
            SELECT
              t.id, t.name, t.short_name AS "shortName", t.primary_color AS "primaryColor", t.logo_url AS "logoUrl",
              COUNT(m.id) FILTER (WHERE m.status = 'finished') AS "played",
              COUNT(m.id) FILTER (WHERE m.status = 'finished' AND ((m.home_team_id = t.id AND m.home_goals > m.away_goals) OR (m.away_team_id = t.id AND m.away_goals > m.home_goals))) AS "won",
              COUNT(m.id) FILTER (WHERE m.status = 'finished' AND m.home_goals = m.away_goals) AS "drawn",
              COUNT(m.id) FILTER (WHERE m.status = 'finished' AND ((m.home_team_id = t.id AND m.home_goals < m.away_goals) OR (m.away_team_id = t.id AND m.away_goals < m.home_goals))) AS "lost",
              COALESCE(SUM(CASE WHEN m.home_team_id = t.id THEN m.home_goals ELSE m.away_goals END) FILTER (WHERE m.status = 'finished'), 0) AS "goalsFor",
              COALESCE(SUM(CASE WHEN m.home_team_id = t.id THEN m.away_goals ELSE m.home_goals END) FILTER (WHERE m.status = 'finished'), 0) AS "goalsAgainst"
            FROM teams t
            LEFT JOIN matches m ON (m.home_team_id = t.id OR m.away_team_id = t.id)
            GROUP BY t.id, t.name, t.short_name, t.primary_color, t.logo_url
          ) s
          ORDER BY s."won" DESC, (s."goalsFor" - s."goalsAgainst") DESC, s."goalsFor" DESC, s.name
        `) as Row[];
        return json({ standings: rows });
      } catch (err) {
        return serverError(`Query failed: ${(err as Error).message}`);
      }
    }

    return notFound(`No route for ${method} ${pathname}`);
  },
};