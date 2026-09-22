INSERT INTO teams (name, short_name, city, primary_color, logo_url) VALUES
  ('Manchester United', 'MUN', 'Manchester', 'DA291C', 'https://resources.premierleague.com/premierleague/badges/t92.svg'),
  ('Arsenal', 'ARS', 'London', 'EF0107', 'https://resources.premierleague.com/premierleague/badges/t3.svg'),
  ('Liverpool', 'LIV', 'Liverpool', 'C8102E', 'https://resources.premierleague.com/premierleague/badges/t11.svg'),
  ('Manchester City', 'MCI', 'Manchester', '6CABDD', 'https://resources.premierleague.com/premierleague/badges/t43.svg'),
  ('Chelsea', 'CHE', 'London', '034694', 'https://resources.premierleague.com/premierleague/badges/t8.svg'),
  ('Tottenham Hotspur', 'TOT', 'London', '132257', 'https://resources.premierleague.com/premierleague/badges/t6.svg')
ON CONFLICT (name) DO NOTHING;

INSERT INTO matches (matchday, kickoff_at, home_team_id, away_team_id, home_goals, away_goals, status, odds_home, odds_draw, odds_away, handicap) VALUES
  (1, '2026-08-15T14:00:00Z', (SELECT id FROM teams WHERE name='Manchester United'), (SELECT id FROM teams WHERE name='Arsenal'), 2, 1, 'finished', 2.10, 3.40, 3.60, NULL),
  (2, '2026-08-22T14:00:00Z', (SELECT id FROM teams WHERE name='Liverpool'), (SELECT id FROM teams WHERE name='Manchester United'), 1, 0, 'finished', 1.75, 3.80, 4.50, NULL),
  (3, '2026-08-29T14:00:00Z', (SELECT id FROM teams WHERE name='Manchester United'), (SELECT id FROM teams WHERE name='Manchester City'), NULL, NULL, 'scheduled', 3.10, 3.30, 2.25, -0.5),
  (4, '2026-09-12T14:00:00Z', (SELECT id FROM teams WHERE name='Chelsea'), (SELECT id FROM teams WHERE name='Manchester United'), 1, 1, 'finished', 2.40, 3.35, 2.80, NULL),
  (5, '2026-09-19T16:30:00Z', (SELECT id FROM teams WHERE name='Tottenham Hotspur'), (SELECT id FROM teams WHERE name='Manchester United'), NULL, NULL, 'scheduled', 2.65, 3.40, 2.55, 0.0),
  (6, '2026-09-26T14:00:00Z', (SELECT id FROM teams WHERE name='Manchester United'), (SELECT id FROM teams WHERE name='Arsenal'), NULL, NULL, 'scheduled', 2.00, 3.50, 3.70, -0.5)
ON CONFLICT (matchday, home_team_id, away_team_id) DO NOTHING;