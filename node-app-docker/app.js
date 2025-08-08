//app.js
const http = require("http");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const Todo = require("./controller");
const { getReqData } = require("./utils");

const PORT = process.env.PORT || 8080;
const HOST = "0.0.0.0";

// ---- Simple auth helpers (file-backed users + in-memory sessions) ----
const USERS_FILE = path.join(__dirname, "users.json");
function readUsers() {
  try {
    const raw = fs.readFileSync(USERS_FILE, "utf8");
    return JSON.parse(raw);
  } catch (_) {
    return [];
  }
}
function writeUsers(users) {
  fs.writeFileSync(USERS_FILE, JSON.stringify(users, null, 2));
}
function parseCookies(req) {
  const header = req.headers["cookie"] || "";
  return header.split("; ").reduce((acc, part) => {
    const idx = part.indexOf("=");
    if (idx > -1) acc[part.slice(0, idx)] = decodeURIComponent(part.slice(idx + 1));
    return acc;
  }, {});
}
function setCookie(res, name, value, opts = {}) {
  const parts = [`${name}=${encodeURIComponent(value)}`];
  if (opts.httpOnly !== false) parts.push("HttpOnly");
  parts.push("Path=/");
  if (opts.maxAge != null) parts.push(`Max-Age=${opts.maxAge}`);
  res.setHeader("Set-Cookie", parts.join("; "));
}
function hashPassword(password, salt) {
  const s = salt || crypto.randomBytes(16).toString("hex");
  const hash = crypto.scryptSync(password, s, 64).toString("hex");
  return `${s}:${hash}`;
}
function verifyPassword(password, stored) {
  const [s, h] = String(stored).split(":" );
  const check = crypto.scryptSync(password, s, 64).toString("hex");
  return crypto.timingSafeEqual(Buffer.from(h, "hex"), Buffer.from(check, "hex"));
}
const sessions = new Map();
function currentUser(req) {
  const { sid } = parseCookies(req);
  if (!sid) return null;
  const user = sessions.get(sid);
  return user || null;
}

function renderHtml(title, body) {
  return `<!doctype html><html><head><meta charset="utf-8"/><title>${title}</title></head><body>${body}</body></html>`;
}

function parseForm(body) {
  return body.split("&").reduce((acc, pair) => {
    const [k, v] = pair.split("=");
    if (k) acc[decodeURIComponent(k)] = decodeURIComponent(v || "");
    return acc;
  }, {});
}

const server = http.createServer(async (req, res) => {
  console.log("Called" + req.method + " : " + req.url);

  // Home page
  if (req.url === "/" && req.method === "GET") {
    const user = currentUser(req);
    const body = `
      <h1>Welcome</h1>
      ${user ? `<p>Logged in as <b>${user.username}</b></p><p><a href="/me">Profile</a></p><form method="post" action="/logout"><button>Logout</button></form>` : `<p><a href="/register">Register</a> or <a href="/login">Login</a></p>`}
    `;
    res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    return res.end(renderHtml("Home", body));
  }

  // Health
  if (req.url === "/health" && req.method === "GET") {
    const healthcheck = { uptime: process.uptime(), message: "OK", timestamp: Date.now() };
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify(healthcheck));
  }

  // Register (GET)
  if (req.url === "/register" && req.method === "GET") {
    const body = `
      <h2>Register</h2>
      <form method="post" action="/register">
        <div><label>Username <input name="username" required></label></div>
        <div><label>Email <input type="email" name="email" required></label></div>
        <div><label>Password <input type="password" name="password" required></label></div>
        <button type="submit">Create account</button>
      </form>`;
    res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    return res.end(renderHtml("Register", body));
  }

  // Register (POST)
  if (req.url === "/register" && req.method === "POST") {
    const raw = await getReqData(req);
    const form = parseForm(raw || "");
    const { username = "", email = "", password = "" } = form;
    if (!username || !email || !password) {
      res.writeHead(400, { "Content-Type": "text/plain" });
      return res.end("All fields are required");
    }
    const users = readUsers();
    if (users.find(u => u.username === username) || users.find(u => u.email === email)) {
      res.writeHead(400, { "Content-Type": "text/plain" });
      return res.end("Username or email already in use");
    }
    const password_hash = hashPassword(password);
    const user = { id: Date.now(), username, email, password_hash };
    users.push(user);
    writeUsers(users);
    const sid = crypto.randomBytes(24).toString("hex");
    sessions.set(sid, { id: user.id, username, email });
    setCookie(res, "sid", sid, { httpOnly: true, maxAge: 60 * 60 * 24 * 7 });
    res.writeHead(302, { Location: "/me" });
    return res.end();
  }

  // Login (GET)
  if (req.url === "/login" && req.method === "GET") {
    const body = `
      <h2>Login</h2>
      <form method="post" action="/login">
        <div><label>Username <input name="username" required></label></div>
        <div><label>Password <input type="password" name="password" required></label></div>
        <button type="submit">Login</button>
      </form>`;
    res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    return res.end(renderHtml("Login", body));
  }

  // Login (POST)
  if (req.url === "/login" && req.method === "POST") {
    const raw = await getReqData(req);
    const form = parseForm(raw || "");
    const { username = "", password = "" } = form;
    const users = readUsers();
    const user = users.find(u => u.username === username);
    if (!user || !verifyPassword(password, user.password_hash)) {
      res.writeHead(400, { "Content-Type": "text/plain" });
      return res.end("Invalid credentials");
    }
    const sid = crypto.randomBytes(24).toString("hex");
    sessions.set(sid, { id: user.id, username: user.username, email: user.email });
    setCookie(res, "sid", sid, { httpOnly: true, maxAge: 60 * 60 * 24 * 7 });
    res.writeHead(302, { Location: "/me" });
    return res.end();
  }

  // Me (GET)
  if (req.url === "/me" && req.method === "GET") {
    const user = currentUser(req);
    if (!user) {
      res.writeHead(401, { "Content-Type": "text/plain" });
      return res.end("Not authenticated");
    }
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify(user));
  }

  // Logout (POST)
  if (req.url === "/logout" && req.method === "POST") {
    const { sid } = parseCookies(req);
    if (sid) sessions.delete(sid);
    setCookie(res, "sid", "", { httpOnly: true, maxAge: 0 });
    res.writeHead(302, { Location: "/" });
    return res.end();
  }

    // /api/todos : GET
    else if (req.url === "/api/todos" && req.method === "GET") {
        // console.log("Called GET : 0.0.0.0:8080/api/todos");
        // get the todos.
        const todos = await new Todo().getTodos();
        // set the status code, and content-type
        res.writeHead(200, { "Content-Type": "application/json" });
        // send the data
        res.end(JSON.stringify(todos));
    }

    // /api/todos/:id : GET
    else if (req.url.match(/\/api\/todos\/([0-9]+)/) && req.method === "GET") {
        // console.log("Called GET : 0.0.0.0:8080/api/todos/{id}");
        try {
            // get id from url
            const id = req.url.split("/")[3];
            // get todo
            const todo = await new Todo().getTodo(id);
            // set the status code and content-type
            res.writeHead(200, { "Content-Type": "application/json" });
            // send the data
            res.end(JSON.stringify(todo));
        } catch (error) {
            // set the status code and content-type
            res.writeHead(404, { "Content-Type": "application/json" });
            // send the error
            res.end(JSON.stringify({ message: error }));
        }
    }

    // /api/todos/:id : DELETE
    else if (
        req.url.match(/\/api\/todos\/([0-9]+)/) &&
        req.method === "DELETE"
    ) {
        // console.log("Called DELETE : 0.0.0.0:8080/api/todos/{id}");
        try {
            // get the id from url
            const id = req.url.split("/")[3];
            // delete todo
            let message = await new Todo().deleteTodo(id);
            // set the status code and content-type
            res.writeHead(200, { "Content-Type": "application/json" });
            // send the message
            res.end(JSON.stringify({ message }));
            //or response status = 204 if no response body is sent
               // res.writeHead(204, { "Content-Type": "application/json" }); 

        } catch (error) {
            // set the status code and content-type
            res.writeHead(404, { "Content-Type": "application/json" });
            // send the error
            res.end(JSON.stringify({ message: error }));
        }
    }

    // /api/todos/:id : UPDATE
    else if (
        req.url.match(/\/api\/todos\/([0-9]+)/) &&
        req.method === "PATCH"
    ) {
        // console.log("Called PATCH : 0.0.0.0:8080/api/todos/{id}");
        try {
            // get the id from the url
            const id = req.url.split("/")[3];
            // update todo
            let updated_todo = await new Todo().updateTodo(id);
            // set the status code and content-type
            res.writeHead(200, { "Content-Type": "application/json" });
            // send the message
            res.end(JSON.stringify(updated_todo));
        } catch (error) {
            // set the status code and content type
            res.writeHead(404, { "Content-Type": "application/json" });
            // send the error
            res.end(JSON.stringify({ message: error }));
        }
    }

    // /api/todos/ : POST
    else if (req.url === "/api/todos" && req.method === "POST") {
        // console.log("Called POST : 0.0.0.0:8080/api/todos");
        // get the data sent along
        let todo_data = await getReqData(req);
        // create the todo
        let todo = await new Todo().createTodo(JSON.parse(todo_data));
        // set the status code and content-type
        res.writeHead(201, { "Content-Type": "application/json" }); //was 200
        //send the todo
        res.end(JSON.stringify(todo));
    }

    // No route present
    else {
        console.warn(
            "This endpoint is not implemented / unavailable at the moment !!"
        );
        res.writeHead(404, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ message: "Route not found" }));
    }
});

server.listen(PORT, () => {
     console.log(`server started on ${HOST}  port: ${PORT}`);
});
