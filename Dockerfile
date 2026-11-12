# AG-CTX · n8n Community Edition (gratuito) con los workflows del agente ya cargados.
# Pensado para Render (plan gratuito, 512 MB). Las claves NO van aquí: se definen como variables secretas en Render.
FROM n8nio/n8n:1.123.94

USER root
RUN mkdir -p /home/node/workflows && chown node:node /home/node/workflows
COPY --chown=node:node AG-CTX_v1.json AG-CTX_MOCK_v1.json /home/node/workflows/
COPY --chown=node:node arranque.sh /home/node/arranque.sh
RUN chmod +x /home/node/arranque.sh
USER node

ENV N8N_PROTOCOL=https \
    N8N_LISTEN_ADDRESS=0.0.0.0 \
    N8N_PROXY_HOPS=1 \
    N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
    GENERIC_TIMEZONE=America/Caracas \
    TZ=America/Caracas \
    N8N_DIAGNOSTICS_ENABLED=false \
    N8N_VERSION_NOTIFICATIONS_ENABLED=false \
    N8N_PERSONALIZATION_ENABLED=false \
    N8N_TEMPLATES_ENABLED=false \
    N8N_RUNNERS_ENABLED=false \
    EXECUTIONS_DATA_PRUNE=true \
    EXECUTIONS_DATA_MAX_AGE=48 \
    EXECUTIONS_DATA_SAVE_ON_SUCCESS=none \
    NODE_OPTIONS=--max-old-space-size=256 \
    NEON_HOST=ep-plain-mud-auow0xqq-pooler.c-10.us-east-1.aws.neon.tech \
    NEON_DATABASE=ag_ctx \
    NEON_USER=neondb_owner

ENTRYPOINT ["/bin/sh", "/home/node/arranque.sh"]
