ALTER TABLE home ALTER COLUMN handicap TYPE text USING handicap::text;

UPDATE home SET handicap = '-0.5' WHERE id = 1;