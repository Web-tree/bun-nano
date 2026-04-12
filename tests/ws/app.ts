import { writeFileSync, readFileSync, existsSync } from "fs";

const LOG = "/tmp/ws-log.txt";
if (!existsSync("/tmp")) Bun.spawnSync(["mkdir", "-p", "/tmp"]);
writeFileSync(LOG, "");

Bun.serve({
  port: 3000,
  fetch(req, server) {
    const url = new URL(req.url);
    if (url.pathname === "/ws" && server.upgrade(req)) return undefined;
    if (url.pathname === "/log") {
      return new Response(readFileSync(LOG, "utf8"), {
        headers: { "content-type": "text/plain" },
      });
    }
    return Response.json({ status: "ok", app: "ws" });
  },
  websocket: {
    open(ws) {
      ws.send("connected");
    },
    message(ws, msg) {
      const line = `${new Date().toISOString()} ${msg}\n`;
      writeFileSync(LOG, readFileSync(LOG, "utf8") + line);
      ws.send(`echo: ${msg}`);
    },
  },
});
console.log("WS app on :3000");
