ARG N8N_VERSION=1.123.87
FROM n8nio/runners:${N8N_VERSION}
USER root


# ติดตั้ง ccxt ใน javascript runner
# ต้องใช้ pnpm เวอร์ชันเดียวกับที่ build node_modules ของ base image (อ่านจาก .modules.yaml)
# ถ้าปล่อยให้ corepack ดึง pnpm ล่าสุด pnpm จะสร้าง node_modules ใหม่จาก package.json
# ซึ่ง n8n ลบ @n8n/di, n8n-core ฯลฯ ออกไปแล้ว -> runner start ไม่ได้ (Cannot find module '@n8n/di')
RUN cd /opt/runners/task-runner-javascript \
    && pnpm_version="$(grep -o 'pnpm@[0-9][0-9.]*' node_modules/.modules.yaml | head -n 1 | cut -d@ -f2)" \
    && test -n "${pnpm_version}" \
    && corepack pnpm@"${pnpm_version}" --allow-build=ccxt --allow-build=bufferutil add ccxt \
    && node -e "require.resolve('@n8n/di'); require.resolve('ccxt')"

RUN cd /opt/runners/task-runner-python && uv pip install numpy pandas
# config allow dependency
COPY n8n-task-runners.json /etc/n8n-task-runners.json

USER runner
