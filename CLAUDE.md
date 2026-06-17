# CLAUDE.md

## What This Is

A devcontainer base template for spinning up isolated, AI-native development sandboxes. Clone or copy this repo to start a new project with a fully configured environment — no application code lives here by design.

## Environment

- **Container**: Node.js 20 (Debian-based), runs as `node` user
- **Workspace**: Bind-mounted at `/workspace`
- **Shell**: Bash with Starship prompt, fzf, direnv, git-delta, persistent history
- **Model**: `ANTHROPIC_MODEL=opus` by default

## Target OpenShift Cluster

The `oc`/`kubectl`/Helm tooling and read-only **kubernetes** MCP target a live PoC cluster (`cluster-rhcl-poc`, AWS `us-east-2`, 6 amd64 nodes):

- **OpenShift version**: 4.20.24 (channel `stable-4.20`)
- **Platform**: AWS (IPI)
- **GitOps**: ArgoCD via the OpenShift GitOps operator (**RHGitOps**)
- **Connectivity**: Red Hat Connectivity Link (Kuadrant) — Gateway API policies

### Installed Operators (OLM)

| Operator | Version | Purpose |
| -------- | ------- | ------- |
| Red Hat Connectivity Link (`rhcl-operator`) | 1.4.0 | Kuadrant control plane — Gateway API policies: `AuthPolicy`, `RateLimitPolicy`, `DNSPolicy`, `TLSPolicy` |
| Authorino / Limitador / DNS | 1.4.0 | Kuadrant data plane backing auth, rate-limit, and DNS policies |
| OpenShift Service Mesh 3 (`servicemeshoperator3`) | 3.3.4 | Istio (Sail) — Gateway API provider; Kiali 2.22 for mesh visualization |
| OpenShift GitOps | 1.20.4 | ArgoCD (RHGitOps) |
| cert-manager | 1.19.0 | TLS certificate management (backs `TLSPolicy`) |
| Red Hat Service Interconnect (`skupper`) | 2.0.1 | Cross-site/cluster networking (RHSI) |
| OpenTelemetry / Tempo / Grafana | — | Observability and distributed tracing |

Assume these CRDs/APIs (Gateway API + Kuadrant policies) are available when reasoning about manifests.

### GitOps Topology (app-of-apps)

ArgoCD runs in the `openshift-gitops` namespace. A root **`bootstrap`** `Application` manages all child apps:

- **Operators/platform**: `operators-system`, `rhcl-operator`, `kuadrant`, `servicemesh-system`, `istio-system`, `ingress-gateway`, `rhsi-system`
- **Observability**: `observability-hub`, `observability-worker`, `opentelemetrycollector`, `tracing-system`
- **Sample workloads**: `travel-agency`, `travel-control`, `travel-portal`, `travel-web`, `echo-api`

Mirror this app-of-apps layout under `/workspace/src` when adding workloads — define an `Application`/`ApplicationSet`, package the workload as a Helm chart, and let `bootstrap` (or a parent app) pick it up.

## Installed Tools

| Category      | Tools                                                              |
| ------------- | ------------------------------------------------------------------ |
| **AI/Agent**  | Claude Code, Plannotator, OpenSpec, OpenCode, Spec-Kit (`specify`) |
| **Languages** | Node.js 20, Python 3 (pip, pipx, uv)                               |
| **Cloud/K8s** | kubectl, Helm 4, oc (OpenShift client)                             |
| **Git**       | gh CLI, git-delta, pre-commit                                      |
| **Security**  | TruffleHog (pre-commit hook + CI workflow)                         |

## Deployment Conventions

- **GitOps only**: All cluster deployments **must** go through ArgoCD following GitOps conventions and patterns. Do **not** apply changes imperatively (`oc apply` / `kubectl apply` / `helm install`) against the cluster — commit declarative artifacts and let ArgoCD reconcile.
- **Repo layout**: All ArgoCD artifacts — manifests, `Application`/`ApplicationSet` definitions, charts, values — live under **`/workspace/src`**.
- **Helm-first**: Package workloads as **Helm charts** wherever possible; treat Helm as the standard. Fall back to raw manifests (or Kustomize) only when a chart genuinely doesn't fit.

## MCP Servers

Defined in `.mcp.json`:

- **context7** — library/framework documentation lookup (requires `CONTEXT7_API_KEY`)
- **kubernetes** — read-only Kubernetes cluster interaction
- **github** — GitHub Copilot MCP API (requires `GITHUB_TOKEN`)

## Shell Aliases

- `claude` — runs Claude Code with `--allow-dangerously-skip-permissions`
- `specify` — runs spec-kit via uvx
- `gen-guid` — generates a UUID
- `bashrc-open` / `bashrc-source` — edit and reload bash config

## Key Conventions

- Always use **context7 MCP** for official documentation lookups before relying on training data.
- Always use **firecrawl MCP** when searching for production patterns or web content.
- Do not create markdown files unless explicitly requested.
- Pre-commit hooks must pass before pushing — TruffleHog will block verified credential leaks.
- This is a template repo: extend it with your own application code, tests, and CI pipelines.
