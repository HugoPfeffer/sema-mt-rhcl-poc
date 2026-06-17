# CLAUDE.md

## What This Is

A devcontainer base template for spinning up isolated, AI-native development sandboxes. Clone or copy this repo to start a new project with a fully configured environment — no application code lives here by design.

## Environment

- **Container**: Node.js 20 (Debian-based), runs as `node` user
- **Workspace**: Bind-mounted at `/workspace`
- **Shell**: Bash with Starship prompt, fzf, direnv, git-delta, persistent history
- **Model**: `ANTHROPIC_MODEL=opus` by default

## Target OpenShift Cluster

The `oc`/`kubectl`/Helm tooling and read-only **kubernetes** MCP target an OpenShift cluster with:

- **OpenShift version**: 4.20
- **GitOps**: ArgoCD via the OpenShift GitOps operator (**RHGitOps**)
- **Connectivity**: Red Hat Connectivity Link operators installed

Assume these CRDs/APIs are available when reasoning about manifests; prefer GitOps (ArgoCD) workflows over imperative `oc apply` for cluster changes.

## Installed Tools

| Category      | Tools                                                              |
| ------------- | ------------------------------------------------------------------ |
| **AI/Agent**  | Claude Code, Plannotator, OpenSpec, OpenCode, Spec-Kit (`specify`) |
| **Languages** | Node.js 20, Python 3 (pip, pipx, uv)                               |
| **Cloud/K8s** | kubectl, Helm 4, oc (OpenShift client)                             |
| **Git**       | gh CLI, git-delta, pre-commit                                      |
| **Security**  | TruffleHog (pre-commit hook + CI workflow)                         |

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
