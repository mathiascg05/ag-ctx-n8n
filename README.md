# AG-CTX · Agente de Contexto de Negocio (n8n en Render)

Sección 01 · Equipo 02 · Proyecto 02 "Retail Content Factory" · Tópicos Especiales para la Gestión de Datos (UCAB).

Este repositorio despliega n8n Community Edition (gratuito) con los workflows del agente AG-CTX. No contiene claves.

## Qué hace el contenedor al arrancar (`arranque.sh`)
1. Crea las credenciales de Neon y OpenRouter a partir de variables secretas.
2. Importa y activa `AG-CTX_v1.json` (agente) y `AG-CTX_MOCK_v1.json` (mock).
3. Arranca n8n y crea la cuenta del editor con `N8N_OWNER_EMAIL` y `N8N_OWNER_PASSWORD`.

Los datos del negocio y la traza viven en Neon (PostgreSQL), así que un reinicio no pierde nada.

## Rutas
| Ruta | Uso |
|---|---|
| `POST /webhook/ag-ctx/invoke` | Invocación del agente (contrato v1.0) |
| `GET /webhook/ag-ctx/health` | Estado del agente y de la base |
| `GET /webhook/ag-ctx/logo?bp=BP-001` | Logo del perfil (PNG) |
| `POST /webhook/ag-ctx-mock/invoke` | Mock para pruebas de integración |

## Render (plan gratuito)
New → Web Service → Public Git Repository → este repo → Runtime **Docker** → Instance type **Free**.
Environment → agregar como variables:

| Variable | Valor |
|---|---|
| `NEON_PASSWORD` | contraseña del rol `neondb_owner` |
| `OPENROUTER_API_KEY` | clave de OpenRouter (el agente usa solo modelos gratuitos `:free`) |
| `N8N_OWNER_EMAIL` | correo para entrar al editor |
| `N8N_OWNER_PASSWORD` | contraseña del editor (8+ caracteres, una mayúscula y un número) |

`.github/workflows/mantener-despierto.yml` hace un ping cada 10 minutos para que Render no duerma el servicio.
Si la URL de Render no es `https://ag-ctx-n8n.onrender.com`, definir la variable del repositorio `AGENTE_URL` (Settings → Secrets and variables → Actions → Variables).
