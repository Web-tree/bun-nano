import express from "express";

const app = express();
app.use(express.json());

app.get("/", (_req, res) => res.json({ status: "ok", app: "express" }));
app.get("/users/:id", (req, res) => res.json({ userId: req.params.id }));
app.post("/echo", (req, res) => res.json(req.body));

app.listen(3000, () => console.log("Express on :3000"));
