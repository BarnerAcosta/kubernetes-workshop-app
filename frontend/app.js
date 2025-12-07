// Configuración de la API
const API_URL =
  window.location.hostname === "localhost"
    ? "http://localhost:3000"
    : "http://backend-service:3000";

// Elementos del DOM
const itemForm = document.getElementById("item-form");
const itemName = document.getElementById("item-name");
const itemDescription = document.getElementById("item-description");
const itemsList = document.getElementById("items-list");
const backendStatus = document.getElementById("backend-status");
const lastUpdate = document.getElementById("last-update");

// Verificar estado del backend
async function checkBackendStatus() {
  try {
    const response = await fetch(`${API_URL}/health`);
    if (response.ok) {
      backendStatus.textContent = "✅ Online";
      backendStatus.className = "status online";
      return true;
    }
  } catch (error) {
    backendStatus.textContent = "❌ Offline";
    backendStatus.className = "status offline";
    return false;
  }
}

// Actualizar timestamp
function updateTimestamp() {
  const now = new Date();
  lastUpdate.textContent = now.toLocaleTimeString("es-ES");
}

// Cargar items
async function loadItems() {
  try {
    const response = await fetch(`${API_URL}/api/items`);
    const result = await response.json();

    if (result.success && result.data.length > 0) {
      itemsList.innerHTML = result.data
        .map(
          (item) => `
                <div class="item">
                    <div class="item-content">
                        <h3>${escapeHtml(item.name)}</h3>
                        ${
                          item.description
                            ? `<p>${escapeHtml(item.description)}</p>`
                            : ""
                        }
                        <span class="item-date">📅 ${new Date(
                          item.created_at
                        ).toLocaleString("es-ES")}</span>
                    </div>
                    <button class="delete-btn" onclick="deleteItem(${
                      item.id
                    })">🗑️ Eliminar</button>
                </div>
            `
        )
        .join("");
    } else {
      itemsList.innerHTML =
        '<p class="empty">No hay items. ¡Agrega el primero!</p>';
    }

    updateTimestamp();
  } catch (error) {
    console.error("Error cargando items:", error);
    itemsList.innerHTML = '<p class="error">❌ Error al cargar items</p>';
  }
}

// Agregar item
itemForm.addEventListener("submit", async (e) => {
  e.preventDefault();

  const name = itemName.value.trim();
  const description = itemDescription.value.trim();

  if (!name) return;

  try {
    const response = await fetch(`${API_URL}/api/items`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ name, description }),
    });

    const result = await response.json();

    if (result.success) {
      itemName.value = "";
      itemDescription.value = "";
      await loadItems();
    } else {
      alert("Error al agregar item: " + result.error);
    }
  } catch (error) {
    console.error("Error:", error);
    alert("Error al conectar con el backend");
  }
});

// Eliminar item
async function deleteItem(id) {
  if (!confirm("¿Estás seguro de eliminar este item?")) return;

  try {
    const response = await fetch(`${API_URL}/api/items/${id}`, {
      method: "DELETE",
    });

    const result = await response.json();

    if (result.success) {
      await loadItems();
    } else {
      alert("Error al eliminar item");
    }
  } catch (error) {
    console.error("Error:", error);
    alert("Error al conectar con el backend");
  }
}

// Escapar HTML para prevenir XSS
function escapeHtml(text) {
  const div = document.createElement("div");
  div.textContent = text;
  return div.innerHTML;
}

// Inicialización
async function init() {
  await checkBackendStatus();
  await loadItems();

  // Actualizar cada 30 segundos
  setInterval(async () => {
    await checkBackendStatus();
    await loadItems();
  }, 30000);
}

init();
