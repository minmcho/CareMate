// ─── Express Server ──────────────────────────────────────────────────────────
import "dotenv/config";
import express from "express";
import path from "path";
import { fileURLToPath } from "url";
import { instagramRouter } from "./instagram/routes.js";
import { startScheduler } from "./instagram/scheduler.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = process.env.API_PORT ?? 3001;

const app = express();
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true }));

// CORS for dev (Vite runs on :3000)
app.use((_req, res, next) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET,POST,PATCH,DELETE,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type,Authorization");
  if (_req.method === "OPTIONS") return res.sendStatus(204);
  next();
});

// ─── API routes ───────────────────────────────────────────────────────────────
app.use("/api/instagram", instagramRouter);

app.get("/api/health", (_req, res) => {
  res.json({ status: "ok", time: new Date().toISOString() });
});

// ─── Start ────────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`✅  API server running on http://localhost:${PORT}`);
  startScheduler(60_000); // Check for due posts every 60 seconds
});
