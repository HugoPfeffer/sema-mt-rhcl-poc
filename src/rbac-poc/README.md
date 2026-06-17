# RHCL RBAC PoC — API access control with Red Hat Connectivity Link

This PoC demonstrates **Red Hat Connectivity Link (RHCL = Kuadrant)** enforcing
**role-based access control at the API edge**. A small sample API is exposed
through the shared `prod-web` Gateway; a single Kuadrant `AuthPolicy` on the
app's `HTTPRoute` authenticates callers by **API key** and authorizes each
endpoint by **role** — *before* traffic reaches the app. The app itself enforces
nothing, which is the point: access decisions are made by RHCL/Authorino.

## What gets deployed

| Resource | Purpose |
| --- | --- |
| `BuildConfig` + `ImageStream` | Build the sample API in-cluster (S2I, no external registry) |
| `Deployment` + `Service` | Run the API on `:8080` |
| `HTTPRoute` | Expose it on `rbac-api.rhcl.sandbox3759.opentlc.com` via `prod-web` |
| `AuthPolicy` (`kuadrant.io/v1`) | API-key auth + per-endpoint role authorization |
| 3 × `Secret` | API keys carrying roles (`admin` / `writer` / `reader`) |

### Endpoint → access matrix

| Endpoint | Method | Requirement | admin | writer | reader | no key |
| --- | --- | --- | :-: | :-: | :-: | :-: |
| `/public` | GET | Public (policy inactive) | ✅ | ✅ | ✅ | ✅ |
| `/api/read` | GET | Any valid key | ✅ | ✅ | ✅ | ❌ 401 |
| `/api/write` | POST | role `writer` | ✅ | ✅ | ❌ 403 | ❌ 401 |
| `/api/admin` | any | role `admin` | ✅ | ❌ 403 | ❌ 403 | ❌ 401 |

Roles are hierarchical: the admin key carries `admin,writer`, so admin is a
superset of writer.

## Prerequisites (clear these before a live demo)

1. **TLS on the `prod-web` HTTPS listener.** The listener references a Secret
   `api-tls` (in `ingress-gateway`) that may not exist yet — without it the
   HTTPS handshake fails before auth is reached. Provision it via cert-manager
   (`Certificate`/`TLSPolicy`), **or** use `curl -k` (the script below does) to
   isolate auth behaviour from cert validation.
2. **ArgoCD app-of-apps pickup.** Ensure the root `bootstrap` Application's
   `source.path` / ApplicationSet generator includes `src/argocd/` so this
   `rbac-poc` Application is discovered. The bootstrap path has been observed
   broken — fix it first, or apply `src/argocd/rbac-poc-application.yaml`
   through your normal ArgoCD onboarding (still declarative; **no `oc apply` of
   the workload manifests** — let ArgoCD reconcile).
3. **Builder image tag.** `values.yaml` uses `nodejs:20-ubi9`; confirm it exists
   with `oc get is nodejs -n openshift -o jsonpath='{.spec.tags[*].name}'` and
   adjust `build.builderImage` if needed.

## Deploy (GitOps)

```bash
# 1. Commit src/ to the GitOps repo and push.
# 2. Register the Application (via bootstrap, or directly through ArgoCD).
# 3. Watch it sync. The Deployment is ImagePullBackOff until the S2I build
#    finishes the first time — this is expected; it recovers automatically.
oc -n rbac-poc get builds,pods,httproute,authpolicy
oc -n rbac-poc get authpolicy rbac-sample-api -o jsonpath='{.status.conditions}' | jq
# AuthPolicy should report Accepted=True and Enforced=True.
```

## Demo — access scenarios

```bash
HOST=rbac-api.rhcl.sandbox3759.opentlc.com
ADMIN=demo-admin-key-do-not-use
WRITER=demo-writer-key-do-not-use
READER=demo-reader-key-do-not-use

# 1) Public, no auth ............................................. expect 200
curl -sk -o /dev/null -w 'public            -> %{http_code}\n' https://$HOST/public

# 2) Authenticated read (reader) ................................ expect 200
curl -sk -o /dev/null -w 'reader  /api/read  -> %{http_code}\n' \
  -H "Authorization: APIKEY $READER" https://$HOST/api/read

# 3) UNAUTHORIZED: no key on a protected path ................... expect 401
curl -sk -o /dev/null -w 'nokey   /api/read  -> %{http_code}\n' https://$HOST/api/read

# 4) Authorized write (writer) .................................. expect 200
curl -sk -o /dev/null -w 'writer  /api/write -> %{http_code}\n' \
  -X POST -H "Authorization: APIKEY $WRITER" https://$HOST/api/write

# 5) ROLE-ESCALATION PREVENTED: reader -> write ................. expect 403
curl -sk -o /dev/null -w 'reader  /api/write -> %{http_code}\n' \
  -X POST -H "Authorization: APIKEY $READER" https://$HOST/api/write

# 6) ROLE-ESCALATION PREVENTED: writer -> admin ................. expect 403
curl -sk -o /dev/null -w 'writer  /api/admin -> %{http_code}\n' \
  -X DELETE -H "Authorization: APIKEY $WRITER" https://$HOST/api/admin

# 7) Authorized admin (admin) ................................... expect 200
curl -sk -o /dev/null -w 'admin   /api/admin -> %{http_code}\n' \
  -X DELETE -H "Authorization: APIKEY $ADMIN" https://$HOST/api/admin

# 8) Bad key .................................................... expect 401
curl -sk -o /dev/null -w 'badkey  /api/read  -> %{http_code}\n' \
  -H "Authorization: APIKEY nope" https://$HOST/api/read
```

Show the injected identity (proves RHCL authenticated the caller, and the app
just echoes it):

```bash
curl -sk -H "Authorization: APIKEY $ADMIN" https://$HOST/api/read | jq .caller
# => { "user": "alice-admin", "groups": ["admin","writer"] }
```

Inspect a denial body/header:

```bash
curl -sk -D - -X POST -H "Authorization: APIKEY $READER" https://$HOST/api/write
# HTTP/2 403 ... x-rhcl-denied-by: authorino-rbac
# {"error":"forbidden","reason":"insufficient_role","policy":"rbac-sample-api"}
```

This covers all three required classes: **authorized** (1,2,4,7),
**unauthorized** 401/403 (3,8 / 5,6), and **role-escalation prevention** (5,6).

## Observability — confirming RHCL made the decision

**Authorino decision logs (primary proof).** Each request logs the resolved
identity, the evaluated rules, `"authorized": true|false`, and the deny reason:

```bash
oc -n kuadrant-system logs deploy/authorino -f \
  | jq 'select(.logger=="authorino.service.auth")'
# Run scenarios 5–7 and watch the "authorized": false entries name the failed rule.
oc -n kuadrant-system logs deploy/authorino --since=5m | grep '"authorized":false'
```

For full per-request detail set the Authorino CR log level to `debug`
**declaratively** (via the operator/GitOps), not imperatively:
`spec.logLevel: debug` on the `Authorino` CR in `kuadrant-system`.

**Istio gateway access logs (status codes at the edge):**

```bash
POD=$(oc -n ingress-gateway get pods \
  -l gateway.networking.k8s.io/gateway-name=prod-web -o name | head -1)
oc -n ingress-gateway logs $POD -c istio-proxy -f | grep '/api/'
# Shows response_code 200/401/403 and the ext_authz (Authorino) interaction.
```

**Tempo / Grafana traces** (the cluster runs OpenTelemetry + Tempo + Grafana).
Point Authorino's tracing at the collector (`Authorino` CR
`spec.tracing.endpoint`, e.g. `http://otel-collector.observability-hub:4317`),
then in Grafana's Tempo datasource query denied requests and inspect the authz
span (matched `AuthConfig`, failed rule):

```
{ .service.name = "authorino" && .http.status_code = 403 }
```

## Notes & production hardening

- **Targeting:** this PoC attaches the policy to the `HTTPRoute`. For a
  platform-wide "deny by default / require authentication everywhere" baseline,
  attach an `AuthPolicy` to the **Gateway** using `spec.defaults` (routes can
  override) or `spec.overrides` (routes cannot loosen).
- **Secrets:** the demo API keys are obviously-fake placeholders in
  `values.yaml`. For anything real, source them from a secret manager
  (External Secrets Operator / sealed-secrets) — never commit live keys
  (TruffleHog blocks verified secrets on commit).
- **Multi-role:** the `incl` operator does string containment. For robust
  list-membership semantics use the OPA/Rego variant shown in
  `templates/authpolicy.yaml`.
- **Identity model:** swap API keys for JWT/OIDC by replacing
  `authentication.api-key-users.apiKey` with `authentication.<name>.jwt`
  (`issuerUrl` of a Keycloak/RHBK realm) and reading roles from
  `auth.identity.realm_access.roles`. Requires standing up the IdP first.
