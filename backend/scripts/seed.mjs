import { neon } from "@neondatabase/serverless";
import { readFile } from "node:fs/promises";
import { readFileSync } from "node:fs";

const url = process.env.DATABASE_URL ?? loadDotDevVars();
if (!url) {
  console.error("Missing DATABASE_URL. Export it or place it in backend/.dev.vars");
  process.exit(1);
}

function loadDotDevVars() {
  try {
    const content = readFileSync(new URL("../.dev.vars", import.meta.url), "utf8");
    for (const line of content.split("\n")) {
      const [key, ...rest] = line.split("=");
      if (key === "DATABASE_URL") return rest.join("=");
    }
  } catch {
    return undefined;
  }
  return undefined;
}

const statements = (await readFile(new URL("../migrations/002_seed.sql", import.meta.url), "utf8"))
  .split(";")
  .map((s) => s.trim())
  .filter(Boolean);

const sql = neon(url, { fetchOptions: { cache: "no-store" } });

for (const statement of statements) {
  const trimmed = statement.replace(/;\s*$/, "");
  console.log(`> ${trimmed.split("\n")[0].slice(0, 80)}...`);
  await sql.query(trimmed);
}

console.log("Seed 002_seed.sql applied.");