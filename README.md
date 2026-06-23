# 🚀 Llama.cpp Blackwell Universal (v1.2.0)

Optimized for NVIDIA RTX 50-Series (Blackwell) & Agentic Workflows.

## 🌟 Qué hay de nuevo en v1.2.0
- **Auto-Discovery LAN**: El servidor ahora es detectable automáticamente por la app **Off Grid** en iOS/Android.
- **Ollama Identity Shim**: Incluye un puente (`ollama_shim.js`) que emula la API de Ollama para garantizar compatibilidad total con apps móviles.
- **Dual-Port Engine**: 
  - Puerto `5050`: Inferencia nativa ultra-rápida (Hermes/CLI).
  - Puerto `11434`: Interfaz de descubrimiento y compatibilidad móvil.
- **Hermes Sync**: Sincronización automática de modelos y estados con el ecosistema de agentes Hermes.
- **Desktop Launchers**: Scripts `.bat` optimizados con expansión de variables para máxima estabilidad.

## 📱 Cómo conectar tu iPhone (Off Grid)
1. Ejecuta `Llama-Server_RTX5080.bat` o `Llama-Server_RTX5080_MTP.bat`.
2. Selecciona **Activar Red LAN** cuando el lanzador lo pregunte.
3. En la app **Off Grid**, simplemente pulsa **Scan**. El servidor aparecerá como `Blackwell-RTX5080`.
4. ¡Empieza a chatear! El sistema traducirá los protocolos automáticamente.

## 🛠️ Requisitos
- Node.js distribuido en el bundle (para el Identity Shim).
- Drivers NVIDIA 555+ para soporte Blackwell nativo.

---
*Developed for the Blackwell Elite Community.*
