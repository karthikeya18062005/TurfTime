require("dotenv").config();
const connectDB = require("./config/db");
const app = require("./app");

const PORT = process.env.PORT || 5000;

connectDB();

app.listen(PORT, () => {
    console.log(`🚀TurfTime Server running on http://localhost:${PORT}`);
});
