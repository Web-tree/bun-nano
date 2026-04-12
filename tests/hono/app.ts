import { Hono } from "hono";

const app = new Hono();
app.get("/", (c) => c.json({ status: "ok", app: "hono" }));
app.get("/users/:id", (c) => c.json({ userId: c.req.param("id") }));
app.post("/echo", async (c) => c.json(await c.req.json()));

export default { port: 3000, fetch: app.fetch };
