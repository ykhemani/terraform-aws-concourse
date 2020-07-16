# Retrieving Secrets from Vault in Concourse CI Pipelines for your API Driven Terraform Enterprise Runs

In our Concourse CI pipelines that will call the Terraform Enterprise (TFE) API, we will need to retrieve TFE Organization tokens and TFE Team tokens depending on the objective of the pipeline. We may also require other secrets that are stored in Vault in order to run our pipeline.

[Concourse](https://concourse-ci.org) can be configured to pull secrets from [HashiCorp](https://hashicorp.com) [Vault](https://vaultproject.io).

## Vault Configuration

### Environment Vairbales

Let's set some environment variables to facilitate our work.
```
export CONCOURSE_SECRETS_ENGINE=concourse
export CONCOURSE_POLICY=concourse-policy
export VAULT_TFE_KV=app.terraform.io
export TFE_ORG=khemani
export APPROLE_PATH=approle
export VAULT_ROLE=concourse-role
```

### Configure KV Secrets Engine for Concourse

Let's define a kv secrets engine that will house the Terraform Enterprise tokens and CMDB data that Concourse may require.

```
vault secrets disable ${CONCOURSE_SECRETS_ENGINE}
vault secrets enable -path=${CONCOURSE_SECRETS_ENGINE} kv
```

### Configure Concourse Policy

Let's define a policy that will enable Concourse to read from this secrets engine.

```
vault policy write "${CONCOURSE_POLICY}" -<<EOF
# Read TFE Tokens
path "${CONCOURSE_SECRETS_ENGINE}/main/*" {
  capabilities = ["read"]
}

# Manage CMDB data
path "${CONCOURSE_SECRETS_ENGINE}/main/cmdb/*" {
  capabilities = ["read"]
}
EOF
```

Let's write some secrets for Concourse to consume.

```
vault kv put ${CONCOURSE_SECRETS_ENGINE}/main/tfe \
  TFE_ORG_TOKEN="the-value-for-the-tfe-org-token" \
  TFE_TEAM_TOKEN="the-value-for-the-tfe-team-token" \
  TFE_ADDR="${VAULT_TFE_KV}" \
  TFE_ORG="${TFE_ORG}"
```

Let's confirm the secret that we just wrote.

```
vault kv get ${CONCOURSE_SECRETS_ENGINE}/main/tfe
```

### Configure AppRole Authentication

Let's enable the AppRole auth method.

```
vault auth disable ${APPROLE_PATH}
vault auth enable -path=${APPROLE_PATH} approle
```

Let's create a named role that our Vault Agent will use to authenticate with the Vault cluster.

```
vault write auth/${APPROLE_PATH}/role/concourse-role \
  secret_id_ttl=1h \
  token_num_uses=0 \
  token_ttl=1h \
  token_max_ttl=24h \
  period=1h \
  token_policies=${CONCOURSE_POLICY} \
  secret_id_num_uses=0
```

Let's generate a Role ID to enable Vault Agent to authenticate with Vault.

```
export VAULT_ROLE_ID=$(vault read -format=json auth/${APPROLE_PATH}/role/concourse-role/role-id | jq -r '.data.role_id')
```

Let's see what that looks like.

```
echo $VAULT_ROLE_ID
```

Let's generate a Secret ID to enable Vault Agent to authenticate with Vault.

```
export VAULT_SECRET_ID=$(vault write -f -format=json auth/${APPROLE_PATH}/role/concourse-role/secret-id | jq -r '.data.secret_id')
```

Let's see what that looks like.

```
echo $VAULT_SECRET_ID
```

### Configure Concourse

Let's configure Concourse Web with the following environment variables.

```
CONCOURSE_VAULT_URL=<vault_addr>
#CONCOURSE_VAULT_CA_CERT=/etc/concourse/ssl/ca.pem
CONCOURSE_VAULT_AUTH_BACKEND=approle
CONCOURSE_VAULT_AUTH_PARAM="role_id:<roles_id>,secret_id:<secret_id>"

CONCOURSE_VAULT_AUTH_BACKEND_MAX_TTL=24h

CONCOURSE_VAULT_PATH_PREFIX=/concourse

```

### Run a Pipeline

Let's log in with fly.

```
fly -t khemani-test-ci login -c <concourse_url>
```

Let's create a test pipeline.

```
---
platform: linux

image_resource:
  type: docker-image
  source: {repository: busybox}

params:
  TFE_ORG_TOKEN: ((tfe.TFE_ORG_TOKEN))
  TFE_TEAM_TOKEN: ((tfe.TFE_TEAM_TOKEN))
  TFE_ADDR: ((tfe.TFE_ADDR))
  TFE_ORG: ((tfe.TFE_ORG))

run:
  path: sh
  args:
  - -exc
  - |
    echo "TFE_ORG_TOKEN is $TFE_ORG_TOKEN";
    echo "TFE_TEAM_TOKEN is $TFE_TEAM_TOKEN"
```

Let's run our pipeline.

```
fly -t khemani-test-ci execute -c ./test.yml
```

---

## Reference:
* [Concourse Vault Credential Manager](https://concourse-ci.org/vault-credential-manager.html)
* [Vault AppRole Auth Method](https://www.vaultproject.io/docs/auth/approle)
* [Vault Policies](https://www.vaultproject.io/docs/concepts/policies.html)
