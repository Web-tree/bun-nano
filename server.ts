const port = Number(process.env.PORT ?? 3000);

Bun.serve({
  port,
  fetch() {
    return new Response("hello from bun-docker-nano\n");
  },
});

console.log(`listening on :${port}`);
