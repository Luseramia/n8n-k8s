# n8n Kubernetes chart

The chart references an externally managed Secret named `n8n-runtime`. Secret
values are never rendered by Helm or committed to this repository. Jenkins
receives them as Vault Agent files, creates or updates the Kubernetes Secret,
builds the custom task-runner image, and commits only its immutable image tag.

## Vault inputs

Create `dev-secrets/n8n` with these fields:

- `N8N_ENCRYPTION_KEY`
- `N8N_DB_PASSWORD`
- `N8N_RUNNERS_AUTH_TOKEN`
- `AI_TEST_PLAN_WEBHOOK_SECRET`
- `GITHUB_WEBHOOK_SECRET`
- `AI_TEST_NOTIFICATION_URL`
- `AI_TEST_NOTIFICATION_TOKEN`

The pipeline reuses these existing fields from `dev-secrets/ai` so the gateway
and n8n cannot drift:

- `AI_TEST_API_TOKEN`
- `AI_TEST_COMPLETION_WEBHOOK_SECRET`

The Vault policy attached to the Jenkins `kaniko` Kubernetes role must also
allow `read` on `dev-secrets/data/n8n`. For a KV v2 mount, a suitable rule is:

```hcl
path "dev-secrets/+/n8n" {
  capabilities = ["create", "list", "read", "update"]
}
```

## Kubernetes Secret keys

Jenkins maps Vault data into `n8n/n8n-runtime` with these keys:

| Kubernetes key | Source |
| --- | --- |
| `n8n-encryption-key` | `dev-secrets/n8n:N8N_ENCRYPTION_KEY` |
| `db-password` | `dev-secrets/n8n:N8N_DB_PASSWORD` |
| `runners-auth-token` | `dev-secrets/n8n:N8N_RUNNERS_AUTH_TOKEN` |
| `ai-test-plan-webhook-secret` | `dev-secrets/n8n:AI_TEST_PLAN_WEBHOOK_SECRET` |
| `ai-test-gateway-token` | `dev-secrets/ai:AI_TEST_API_TOKEN` |
| `ai-test-completion-webhook-secret` | `dev-secrets/ai:AI_TEST_COMPLETION_WEBHOOK_SECRET` |
| `github-webhook-secret` | `dev-secrets/n8n:GITHUB_WEBHOOK_SECRET` |
| `ai-test-notification-url` | `dev-secrets/n8n:AI_TEST_NOTIFICATION_URL` |
| `ai-test-notification-token` | `dev-secrets/n8n:AI_TEST_NOTIFICATION_TOKEN` |

The chart creates only the namespaced Role and RoleBinding that allow the
`jenkins/kaniko` ServiceAccount to manage that exact Secret name. It does not
create the Secret itself.

## Migration order

1. Put the **current** n8n encryption key in Vault. Do not generate a new one:
   changing it makes existing n8n credentials unreadable.
2. Populate all other Vault fields and update the Jenkins Vault policy.
3. Deploy this chart revision. With one replica, the existing pod remains
   available while a replacement waits for `n8n-runtime`.
4. Run the Jenkins pipeline. It applies `n8n-runtime`, builds the runner, and
   publishes the new image tag.
5. Confirm both containers become ready and the AI test workflows can read the
   required environment variables without printing their values.

The old values remain in Git history even after removal from the current tree.
Rotate the database password, runner token, webhook secrets, and notification
token after the migration. Treat the encryption key separately as described
above; rotating it requires an n8n credential migration or re-entry plan.

## Validation

```console
helm lint .
helm template n8n . --namespace n8n >/tmp/n8n-rendered.yaml
```
