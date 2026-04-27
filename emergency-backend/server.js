const express = require("express");
const http = require("http");
const cors = require("cors");
const { Server } = require("socket.io");

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
  },
});

let emergencyData = {
  status: "Resolved",
  message: "",
  location: "",
};

// API: Report Emergency
app.post("/report-emergency", (req, res) => {
  const { message, location } = req.body;

  emergencyData = {
    status: "Active",
    message,
    location,
  };

  io.emit("emergency-update", emergencyData);

  res.json({ success: true });
});

// API: Get Status
app.get("/get-status", (req, res) => {
  res.json(emergencyData);
});

// Socket Connection
io.on("connection", (socket) => {
  console.log("User connected");

  socket.emit("emergency-update", emergencyData);
});

server.listen(5000, () => {
  console.log("Server running on port 5000");
});