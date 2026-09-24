ARG N8N_VERSION=1.123.36
FROM n8nio/runners:${N8N_VERSION}
USER root


# ติดตั้ง ccxt ใน javascript runner
RUN cd /opt/runners/task-runner-javascript \
    && pnpm --allow-build=ccxt --allow-build=bufferutil add ccxt

RUN cd /opt/runners/task-runner-python && uv pip install numpy pandas
# config allow dependency
COPY n8n-task-runners.json /etc/n8n-task-runners.json

USER runner
