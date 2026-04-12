import { Elysia } from "elysia";

new Elysia()
  .get("/", () => ({ status: "ok", app: "elysia" }))
  .get("/users/:id", ({ params }) => ({ userId: params.id, name: "Alice" }))
  .post("/echo", ({ body }) => body)
  .listen(3000);

console.log("Elysia on :3000");
