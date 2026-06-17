# rbac-sample-api

A minimal Express API used by the **RHCL RBAC PoC**. It enforces **no** access
control itself — authentication and role-based authorization are applied at the
gateway by Red Hat Connectivity Link (Kuadrant `AuthPolicy` + Authorino). See
`../../rbac-poc/README.md` for the full walkthrough.

## Endpoints

| Path | Method | Access requirement (enforced by RHCL) |
| --- | --- | --- |
| `/public` | GET | Public — anonymous |
| `/api/read` | GET | Any valid API key (authenticated) |
| `/api/write` | POST | Role `writer` |
| `/api/admin` | any | Role `admin` |
| `/healthz` | GET | Probe only (never behind auth) |

Authenticated responses echo `caller.user` / `caller.groups` from the
`x-auth-username` / `x-auth-groups` headers that RHCL injects on a successful
auth decision.

## Run locally

```bash
npm install
npm start
# In another shell — no identity headers locally, so caller shows "anonymous":
curl -s localhost:8080/public        | jq
curl -s localhost:8080/api/read      | jq
curl -s -X POST localhost:8080/api/write | jq
```

## How it is built on-cluster

The Helm chart (`../../rbac-poc`) builds this directory in-cluster with an
OpenShift **Source-to-Image** `BuildConfig` (`nodejs` builder) — no external
registry or image push is required. `contextDir` points at this folder in the
GitOps repo.
