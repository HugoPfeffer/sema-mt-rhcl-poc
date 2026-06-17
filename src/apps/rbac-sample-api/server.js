'use strict';

// rbac-sample-api — a tiny API for the RHCL (Kuadrant) RBAC PoC.
//
// The app itself enforces NO access control. Authentication and per-endpoint,
// role-based authorization are enforced at the gateway edge by Red Hat
// Connectivity Link (Kuadrant AuthPolicy + Authorino) BEFORE a request ever
// reaches this process. When a request is authorized, RHCL injects the caller's
// identity as request headers (x-auth-username / x-auth-groups) which the
// authenticated handlers echo back, so a response visibly proves *who* RHCL let
// through.

const express = require('express');

const app = express();
const PORT = process.env.PORT || 8080;

// Build a uniform response body describing the endpoint and the caller that
// RHCL authenticated (identity comes from headers injected by the AuthPolicy).
function payload(endpoint, req) {
  return {
    endpoint,
    method: req.method,
    path: req.originalUrl,
    enforcedBy: 'Red Hat Connectivity Link (Kuadrant AuthPolicy + Authorino)',
    caller: {
      user: req.get('x-auth-username') || 'anonymous',
      groups: (req.get('x-auth-groups') || '')
        .split(',')
        .map((g) => g.trim())
        .filter(Boolean),
    },
  };
}

// Liveness/readiness probe — never placed behind auth.
app.get('/healthz', (_req, res) => res.json({ status: 'ok' }));

// Public — the AuthPolicy is inactive for this path, so it is reachable anonymously.
app.get('/public', (req, res) => res.json(payload('public', req)));

// Authenticated — any valid API key (no specific role required).
app.get('/api/read', (req, res) => res.json(payload('read', req)));

// Role-restricted — requires the 'writer' role.
app.post('/api/write', (req, res) => res.json(payload('write', req)));

// Role-restricted — requires the 'admin' role (any method, incl. DELETE).
app.all('/api/admin', (req, res) => res.json(payload('admin', req)));

// Anything else.
app.use((req, res) =>
  res.status(404).json({ error: 'not_found', path: req.originalUrl }),
);

app.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`rbac-sample-api listening on :${PORT}`);
});
