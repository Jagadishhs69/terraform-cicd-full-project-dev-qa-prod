const express = require('express');
const { Pool } = require('pg');

const app = express();
const port = 3000;

// Log all DB environment variables (but mask password for security)
console.log("DB Config:");
console.log("DB_USER:", process.env.DB_USER);
console.log("DB_HOST:", process.env.DB_HOST);
console.log("DB_NAME:", process.env.DB_NAME || 'postgres');
console.log("DB_PORT:", process.env.DB_PORT || 5432);
console.log("DB_PASSWORD:", process.env.DB_PASSWORD ? "**** (set)" : "NOT SET");

// Create PostgreSQL pool
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME || 'postgres',
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT || 5432,
  ssl: {
    rejectUnauthorized: false
  }
});

// Root endpoint
app.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.send(`✅ Hello from Node.js! Current time from DB: ${result.rows[0].now}`);
  } catch (err) {
    console.error("❌ Database connection error details:", err);
    res.status(500).send(`Database connection error: ${err.message}`);
  }
});

// Start server
app.listen(port, () => {
  console.log(`🚀 App running on port ${port}`);
});
