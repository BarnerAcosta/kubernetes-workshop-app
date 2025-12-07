const express = require("express");
const cors = require("cors");
const mysql = require("mysql2/promise");
require("dotenv").config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Configuración de base de datos
const dbConfig = {
  host: process.env.DB_HOST || "localhost",
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "testdb",
};

let db;

// Inicializar conexión a base de datos
async function initDB() {
  try {
    db = await mysql.createConnection(dbConfig);
    console.log("✅ Conectado a la base de datos MySQL");

    // Crear tabla de ejemplo si no existe
    await db.execute(`
      CREATE TABLE IF NOT EXISTS items (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
  } catch (error) {
    console.error("❌ Error conectando a la base de datos:", error.message);
    // Continuar sin DB para health checks
  }
}

// Health check endpoint
app.get("/health", (req, res) => {
  res.status(200).json({
    status: "OK",
    timestamp: new Date().toISOString(),
    service: "backend-api",
    version: "1.0.0",
  });
});

// GET - Obtener todos los items
app.get("/api/items", async (req, res) => {
  try {
    if (!db) {
      return res.status(503).json({ error: "Base de datos no disponible" });
    }
    const [rows] = await db.execute(
      "SELECT * FROM items ORDER BY created_at DESC"
    );
    res.json({ success: true, data: rows });
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST - Crear nuevo item
app.post("/api/items", async (req, res) => {
  try {
    if (!db) {
      return res.status(503).json({ error: "Base de datos no disponible" });
    }
    const { name, description } = req.body;

    if (!name) {
      return res
        .status(400)
        .json({ success: false, error: "El nombre es requerido" });
    }

    const [result] = await db.execute(
      "INSERT INTO items (name, description) VALUES (?, ?)",
      [name, description || ""]
    );

    res.status(201).json({
      success: true,
      data: { id: result.insertId, name, description },
    });
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// DELETE - Eliminar item
app.delete("/api/items/:id", async (req, res) => {
  try {
    if (!db) {
      return res.status(503).json({ error: "Base de datos no disponible" });
    }
    const { id } = req.params;
    await db.execute("DELETE FROM items WHERE id = ?", [id]);
    res.json({ success: true, message: "Item eliminado" });
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Iniciar servidor
app.listen(PORT, async () => {
  console.log(`🚀 Servidor backend ejecutándose en puerto ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV || "production"}`);
  await initDB();
});
