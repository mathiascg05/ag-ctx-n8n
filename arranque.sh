#!/bin/sh
# Arranque del agente (Render u otro servidor con Docker): credenciales desde secretos -> importar workflows -> activar -> n8n -> cuenta de administrador.
set -e
WF_DIR="${WF_DIR:-/home/node/workflows}"
# Render entrega el puerto en PORT; en otros entornos se usa N8N_PORT o 5678
export N8N_PORT="${PORT:-${N8N_PORT:-5678}}"
PORT="$N8N_PORT"

# URL pública: Render define RENDER_EXTERNAL_URL (ej. https://ag-ctx-n8n.onrender.com); Hugging Face, SPACE_HOST
if [ -n "$RENDER_EXTERNAL_URL" ] && [ -z "$WEBHOOK_URL" ]; then
  export WEBHOOK_URL="${RENDER_EXTERNAL_URL%/}/"
  export N8N_HOST="${RENDER_EXTERNAL_HOSTNAME:-$(echo "$RENDER_EXTERNAL_URL" | sed 's#https://##; s#/.*##')}"
  export N8N_EDITOR_BASE_URL="$WEBHOOK_URL"
fi
if [ -n "$SPACE_HOST" ] && [ -z "$WEBHOOK_URL" ]; then
  export WEBHOOK_URL="https://${SPACE_HOST}/"
  export N8N_HOST="$SPACE_HOST"
  export N8N_EDITOR_BASE_URL="https://${SPACE_HOST}/"
fi

faltan=""
for v in NEON_PASSWORD GEMINI_API_KEY N8N_OWNER_EMAIL N8N_OWNER_PASSWORD; do
  eval "val=\${$v:-}"; [ -z "$val" ] && faltan="$faltan $v"
done
[ -n "$faltan" ] && echo "AVISO: faltan secretos:$faltan (el agente arrancará, pero sin ellos no funcionará del todo)"

# 1) Credenciales (los ids coinciden con los que usan los workflows). El archivo se borra enseguida.
CRED_FILE="$(mktemp)"
node -e '
const e = process.env;
const creds = [
  { id: "NEON_AG_CTX", name: "Neon AG-CTX", type: "postgres",
    data: { host: e.NEON_HOST, database: e.NEON_DATABASE, user: e.NEON_USER, password: e.NEON_PASSWORD || "",
            port: Number(e.NEON_PORT || 5432), ssl: e.NEON_SSL || "require", maxConnections: 10 } },
  { id: "GEMINI", name: "Google Gemini(PaLM) Api account", type: "googlePalmApi",
    data: { host: "https://generativelanguage.googleapis.com", apiKey: e.GEMINI_API_KEY || "" } },
];
require("fs").writeFileSync(process.argv[1], JSON.stringify(creds));
' "$CRED_FILE"
n8n import:credentials --input="$CRED_FILE"
rm -f "$CRED_FILE"

# 2) Workflows y activación
n8n import:workflow --separate --input="$WF_DIR"
n8n update:workflow --all --active=true

# 3) n8n
n8n start &
PID=$!
i=0
until wget -q -O /dev/null "http://127.0.0.1:${PORT}/healthz" 2>/dev/null; do
  i=$((i+1)); [ $i -gt 120 ] && { echo "n8n no arrancó"; exit 1; }
  sleep 1
done

# 4) Cuenta de administrador (la base de n8n es nueva en cada arranque)
if [ -n "${N8N_OWNER_EMAIL:-}" ] && [ -n "${N8N_OWNER_PASSWORD:-}" ]; then
  node -e '
  const e = process.env, url = `http://127.0.0.1:${e.N8N_PORT || 5678}/rest/owner/setup`;
  const body = JSON.stringify({ email: e.N8N_OWNER_EMAIL, firstName: "Equipo", lastName: "02", password: e.N8N_OWNER_PASSWORD });
  (async () => {
    for (let i = 0; i < 90; i++) {   // healthz responde antes de que carguen las rutas REST: reintentar
      try {
        const r = await fetch(url, { method: "POST", headers: { "Content-Type": "application/json", "browser-id": "arranque" }, body });
        if (r.status === 200) return console.log("Cuenta de administrador: creada");
        if (r.status === 400) return console.log("Cuenta de administrador: ya existía o datos inválidos (" + (await r.text()).slice(0, 120) + ")");
      } catch (err) {}
      await new Promise(res => setTimeout(res, 1000));
    }
    console.log("Cuenta de administrador: no se pudo crear");
  })();
  '
else
  echo "AVISO: sin N8N_OWNER_EMAIL/N8N_OWNER_PASSWORD el editor queda sin administrador; defínelos como secretos."
fi
echo "AG-CTX listo en ${WEBHOOK_URL:-http://localhost:${PORT}/}"
wait $PID
