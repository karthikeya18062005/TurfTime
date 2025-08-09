const express = require("express");
const cors = require("cors");
const userRoutes = require("./routes/userRoutes");
const authRoutes = require("./routes/authRoutes");

const app = express();

app.use(cors());
app.use(express.json());
// app.js

app.use((req, res, next) => {
    console.log(`👉 Incoming Request: ${req.method} ${req.originalUrl}`);
    console.log(`📦 Request Body:`, req.body);

    const start = Date.now();

    res.on('finish', () => {
        
        console.log(`✅ Response: ${res.statusCode} ,${res.statusMessage} [${req.method} ${req.originalUrl}] (${Date.now() - start}ms)`);
    });

    next();
});

// Routes
app.use("/api/user", userRoutes);
app.use("/api/auth", authRoutes);
app.get("/", (req, res) => {
    res.send("🚀 TurfTime API is running...");
});

module.exports = app;


