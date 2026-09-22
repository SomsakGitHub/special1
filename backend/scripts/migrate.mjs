import { neon } from "@neondatabase/serverless";
import { readFile, readdir } from "node:fs/promises";
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

const sql = neon(url, { fetchOptions: { cache: "no-store" } });

const dir = new URL("../migrations/", import.meta.url);
const files = (await readdir(dir)).filter((f) => f.endsWith(".sql")).sort();

for (const file of files) {
  const statements = (await readFile(new URL(file, dir), "utf8"))
    .split(";")
    .map((s) => s.trim())
    .filter(Boolean);

  for (const statement of statements) {
    console.log(`[${file}] > ${statement.split("\n")[0].slice(0, 80)}...`);
    await sql.query(statement);
  }
}

console.log(`Applied ${files.length} migration file(s).`);