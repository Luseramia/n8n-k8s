pipeline {
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
metadata:
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "kaniko"
    vault.hashicorp.com/template-config-exit-on-retry-failure: "true"
    vault.hashicorp.com/agent-inject-secret-n8n-encryption-key: "dev-secrets/data/n8n"
    vault.hashicorp.com/error-on-missing-key-n8n-encryption-key: "true"
    vault.hashicorp.com/agent-inject-template-n8n-encryption-key: |
      {{- with secret "dev-secrets/data/n8n" -}}{{ .Data.data.N8N_ENCRYPTION_KEY }}{{- end -}}
    vault.hashicorp.com/agent-inject-secret-n8n-db-password: "dev-secrets/data/n8n"
    vault.hashicorp.com/error-on-missing-key-n8n-db-password: "true"
    vault.hashicorp.com/agent-inject-template-n8n-db-password: |
      {{- with secret "dev-secrets/data/n8n" -}}{{ .Data.data.N8N_DB_PASSWORD }}{{- end -}}
    vault.hashicorp.com/agent-inject-secret-n8n-runners-auth-token: "dev-secrets/data/n8n"
    vault.hashicorp.com/error-on-missing-key-n8n-runners-auth-token: "true"
    vault.hashicorp.com/agent-inject-template-n8n-runners-auth-token: |
      {{- with secret "dev-secrets/data/n8n" -}}{{ .Data.data.N8N_RUNNERS_AUTH_TOKEN }}{{- end -}}
    vault.hashicorp.com/agent-inject-secret-ai-test-plan-webhook-secret: "dev-secrets/data/n8n"
    vault.hashicorp.com/error-on-missing-key-ai-test-plan-webhook-secret: "true"
    vault.hashicorp.com/agent-inject-template-ai-test-plan-webhook-secret: |
      {{- with secret "dev-secrets/data/n8n" -}}{{ .Data.data.AI_TEST_PLAN_WEBHOOK_SECRET }}{{- end -}}
    vault.hashicorp.com/agent-inject-secret-github-webhook-secret: "dev-secrets/data/n8n"
    vault.hashicorp.com/error-on-missing-key-github-webhook-secret: "true"
    vault.hashicorp.com/agent-inject-template-github-webhook-secret: |
      {{- with secret "dev-secrets/data/n8n" -}}{{ .Data.data.GITHUB_WEBHOOK_SECRET }}{{- end -}}
    vault.hashicorp.com/agent-inject-secret-ai-test-notification-url: "dev-secrets/data/n8n"
    vault.hashicorp.com/error-on-missing-key-ai-test-notification-url: "true"
    vault.hashicorp.com/agent-inject-template-ai-test-notification-url: |
      {{- with secret "dev-secrets/data/n8n" -}}{{ .Data.data.AI_TEST_NOTIFICATION_URL }}{{- end -}}
    vault.hashicorp.com/agent-inject-secret-ai-test-notification-token: "dev-secrets/data/n8n"
    vault.hashicorp.com/error-on-missing-key-ai-test-notification-token: "true"
    vault.hashicorp.com/agent-inject-template-ai-test-notification-token: |
      {{- with secret "dev-secrets/data/n8n" -}}{{ .Data.data.AI_TEST_NOTIFICATION_TOKEN }}{{- end -}}
    vault.hashicorp.com/agent-inject-secret-ai-test-gateway-token: "dev-secrets/data/ai"
    vault.hashicorp.com/error-on-missing-key-ai-test-gateway-token: "true"
    vault.hashicorp.com/agent-inject-template-ai-test-gateway-token: |
      {{- with secret "dev-secrets/data/ai" -}}{{ .Data.data.AI_TEST_API_TOKEN }}{{- end -}}
    vault.hashicorp.com/agent-inject-secret-ai-test-completion-webhook-secret: "dev-secrets/data/ai"
    vault.hashicorp.com/error-on-missing-key-ai-test-completion-webhook-secret: "true"
    vault.hashicorp.com/agent-inject-template-ai-test-completion-webhook-secret: |
      {{- with secret "dev-secrets/data/ai" -}}{{ .Data.data.AI_TEST_COMPLETION_WEBHOOK_SECRET }}{{- end -}}
spec:
  serviceAccountName: kaniko
  automountServiceAccountToken: true
  containers:
    - name: helper
      image: alpine/git:2.49.1
      command: ["sleep"]
      args: ["99d"]
      tty: true
      volumeMounts:
        - name: workspace
          mountPath: /ci-workspace
    - name: kaniko
      image: gcr.io/kaniko-project/executor:v1.23.2-debug
      command: ["sleep"]
      args: ["99d"]
      tty: true
      volumeMounts:
        - name: workspace
          mountPath: /ci-workspace
        - name: docker-config
          mountPath: /kaniko/.docker
    - name: kubectl
      image: alpine/k8s:1.32.9
      command: ["sleep"]
      args: ["99d"]
      tty: true
      volumeMounts:
        - name: workspace
          mountPath: /ci-workspace
  volumes:
    - name: workspace
      emptyDir: {}
    - name: docker-config
      emptyDir: {}
"""
    }
  }

  options {
    skipDefaultCheckout(true)
    buildDiscarder(logRotator(numToKeepStr: '20'))
    disableConcurrentBuilds()
    timeout(time: 45, unit: 'MINUTES')
    timestamps()
  }

  environment {
    SOURCE_GIT_REPO = 'git@github.com:Luseramia/n8n-k8s.git'
    SOURCE_GIT_BRANCH = 'main'
    REGISTRY = 'registry.registry.svc.cluster.local:5000'
    IMAGE_NAME = 'n8n-runner'
    IMAGE_TAG = "${BUILD_NUMBER}"
    KUBERNETES_NAMESPACE = 'n8n'
    RUNTIME_SECRET_NAME = 'n8n-runtime'
    VAULT_SECRET_DIR = '/vault/secrets'
  }

  stages {
    stage('Checkout') {
      steps {
        withCredentials([sshUserPrivateKey(
          credentialsId: 'github_key',
          keyFileVariable: 'GITHUB_KEY'
        )]) {
          container('helper') {
            sh '''
              set -eu
              rm -rf -- /ci-workspace/source
              mkdir -p /ci-workspace/source ~/.ssh
              chmod 700 ~/.ssh

              cat > ~/.ssh/config <<'SSHCFG'
Host github.com
    Hostname ssh.github.com
    Port 443
    StrictHostKeyChecking yes
SSHCFG
              ssh-keyscan -p 443 ssh.github.com > ~/.ssh/known_hosts 2>/dev/null
              chmod 600 ~/.ssh/config ~/.ssh/known_hosts
              export GIT_SSH_COMMAND="ssh -i ${GITHUB_KEY}"

              git clone --branch "${SOURCE_GIT_BRANCH}" --single-branch \
                "${SOURCE_GIT_REPO}" /ci-workspace/source
              git config --global --add safe.directory /ci-workspace/source
              git -C /ci-workspace/source rev-parse HEAD
            '''
          }
        }
      }
    }

    stage('Validate chart') {
      steps {
        container('kubectl') {
          sh '''
            set -eu
            cd /ci-workspace/source
            helm lint .
            helm template n8n . --namespace "${KUBERNETES_NAMESPACE}" > /ci-workspace/rendered.yaml
            grep -F 'name: n8n-runtime' /ci-workspace/rendered.yaml >/dev/null
            grep -F 'key: ai-test-plan-webhook-secret' /ci-workspace/rendered.yaml >/dev/null
            grep -F 'kind: Role' /ci-workspace/rendered.yaml >/dev/null
          '''
        }
        container('helper') {
          sh '''
            set -eu
            cd /ci-workspace/source
            test -z "$(git status --porcelain)"
          '''
        }
      }
    }

    stage('Apply runtime Secret') {
      steps {
        container('kubectl') {
          sh '''
            set +x
            set -eu

            for file in \
              n8n-encryption-key \
              n8n-db-password \
              n8n-runners-auth-token \
              ai-test-plan-webhook-secret \
              github-webhook-secret \
              ai-test-notification-url \
              ai-test-notification-token \
              ai-test-gateway-token \
              ai-test-completion-webhook-secret
            do
              test -s "${VAULT_SECRET_DIR}/${file}"
            done

            attempt=1
            max_attempts=120
            error_file=/tmp/n8n-runtime-secret.err
            while ! kubectl -n "${KUBERNETES_NAMESPACE}" create secret generic "${RUNTIME_SECRET_NAME}" \
              --from-file=n8n-encryption-key="${VAULT_SECRET_DIR}/n8n-encryption-key" \
              --from-file=db-password="${VAULT_SECRET_DIR}/n8n-db-password" \
              --from-file=runners-auth-token="${VAULT_SECRET_DIR}/n8n-runners-auth-token" \
              --from-file=ai-test-plan-webhook-secret="${VAULT_SECRET_DIR}/ai-test-plan-webhook-secret" \
              --from-file=ai-test-gateway-token="${VAULT_SECRET_DIR}/ai-test-gateway-token" \
              --from-file=ai-test-completion-webhook-secret="${VAULT_SECRET_DIR}/ai-test-completion-webhook-secret" \
              --from-file=github-webhook-secret="${VAULT_SECRET_DIR}/github-webhook-secret" \
              --from-file=ai-test-notification-url="${VAULT_SECRET_DIR}/ai-test-notification-url" \
              --from-file=ai-test-notification-token="${VAULT_SECRET_DIR}/ai-test-notification-token" \
              --dry-run=client -o yaml \
              | kubectl apply -f - >/dev/null 2>"${error_file}"
            do
              if [ "${attempt}" -eq 1 ] || [ $((attempt % 12)) -eq 0 ]; then
                echo "Waiting for n8n namespace and Jenkins Secret RBAC (${attempt}/${max_attempts})" >&2
                sed -n '1,5p' "${error_file}" >&2
              fi
              if [ "${attempt}" -ge "${max_attempts}" ]; then
                echo 'Timed out applying n8n runtime Secret' >&2
                rm -f -- "${error_file}"
                exit 1
              fi
              attempt=$((attempt + 1))
              sleep 5
            done
            rm -f -- "${error_file}"
            kubectl -n "${KUBERNETES_NAMESPACE}" get secret "${RUNTIME_SECRET_NAME}" >/dev/null
            echo 'Applied n8n runtime Secret from Vault'
          '''
        }
      }
    }

    stage('Build and push runner') {
      steps {
        container('kaniko') {
          sh '''
            set -eu
            destination="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
            /kaniko/executor \
              --context=/ci-workspace/source \
              --dockerfile=/ci-workspace/source/Dockerfile \
              --destination="${destination}" \
              --cache=true \
              --cache-repo="${REGISTRY}/kaniko-cache/${IMAGE_NAME}" \
              --insecure \
              --skip-tls-verify \
              --snapshot-mode=redo
          '''
        }
      }
    }

    stage('Publish image tag') {
      steps {
        withCredentials([sshUserPrivateKey(
          credentialsId: 'github_key',
          keyFileVariable: 'GITHUB_KEY'
        )]) {
          container('helper') {
            sh '''
              set -eu
              cd /ci-workspace/source
              sed -i -E \
                "/^runnerImage:/,/^[^[:space:]]/{s/^  tag: .*/  tag: \"${IMAGE_TAG}\"/;}" \
                values.yaml
              grep -A2 '^runnerImage:' values.yaml | grep -F "tag: \"${IMAGE_TAG}\""

              git config user.email 'jenkins@ci.local'
              git config user.name 'Jenkins CI'
              git add -- values.yaml
              if git diff --cached --quiet; then
                echo 'Runner image tag is already current'
              else
                git commit -m "Deploy n8n runner ${IMAGE_TAG} [skip ci]"
                export GIT_SSH_COMMAND="ssh -i ${GITHUB_KEY}"
                git push origin "${SOURCE_GIT_BRANCH}"
              fi
            '''
          }
        }
      }
    }
  }
}
