DROP TABLE IF EXISTS matches;
DROP TABLE IF EXISTS teams;

CREATE TABLE IF NOT EXISTS home (
  id smallint PRIMARY KEY CHECK (id = 1),
  club text NOT NULL,
  handicap numeric
);

INSERT INTO home (id, club, handicap) VALUES (1, 'Manchester United', -0.5)
ON CONFLICT (id) DO NOTHING;