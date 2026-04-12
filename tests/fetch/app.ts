Bun.serve({
  port: 3000,
  async fetch(req) {
    const url = new URL(req.url);
    if (url.pathname === "/ip") {
      const r = await fetch("https://api.ipify.org?format=json");
      return Response.json(await r.json());
    }
    if (url.pathname === "/joke") {
      const r = await fetch("https://official-joke-api.appspot.com/random_joke");
      return Response.json(await r.json());
    }
    return Response.json({ status: "ok", app: "fetch" });
  },
});
console.log("Fetch app on :3000");
