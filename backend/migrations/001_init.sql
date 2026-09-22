CREATE TABLE IF NOT EXISTS teams (
  id serial PRIMARY KEY,
  name text NOT NULL UNIQUE,
  short_name text NOT NULL,
  city text,
  primary_color text,
  logo_url text
);

CREATE TABLE IF NOT EXISTS matches (
  id serial PRIMARY KEY,
  matchday integer NOT NULL,
  kickoff_at timestamptz,
  home_team_id integer NOT NULL REFERENCES teams(id),
  away_team_id integer NOT NULL REFERENCES teams(id),
  home_goals integer,
  away_goals integer,
  status text NOT NULL DEFAULT 'scheduled'
    CHECK (status IN ('scheduled', 'finished', 'postponed')),
  odds_home numeric,
  odds_draw numeric,
  odds_away numeric,
  CHECK (home_team_id <> away_team_id)
);

CREATE INDEX IF NOT EXISTS idx_matches_matchday ON matches (matchday);
CREATE INDEX IF NOT EXISTS idx_matches_status ON matches (status);

CREATE UNIQUE INDEX IF NOT EXISTS uq_matches_fixture ON matches (matchday, home_team_id, away_team_id);