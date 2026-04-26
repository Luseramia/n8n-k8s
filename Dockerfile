FROM n8nio/runners:nightly
USER root


# ติดตั้ง ccxt ใน javascript runner
RUN cd /opt/runners/task-runner-javascript && pnpm add ccxt

RUN cd /opt/runners/task-runner-python && uv pip install numpy pandas
# config allow dependency
COPY n8n-task-runners.json /etc/n8n-task-runners.json

RUN pnpm approve-builds
USER node
