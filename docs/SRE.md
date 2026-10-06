# Monitoring / SRE

## Deployed in the lab (`bootstrap` layer)
- Log Analytics workspace (30 day retention, 0.5 GB/day cap).
- Key Vault audit logs and storage metrics sent to Log Analytics via diagnostic settings.
- Action group (email) and a metric alert: storage availability below 99% over 15 min (severity 2).

## Kubernetes and production design
Deployed on the dev cluster: the website pod reading Key Vault through workload identity, Container Insights (logs and metrics to the same Log Analytics workspace) and the Flux
status visible through the Azure API. Not deployed, design only: the items below.

- **Metrics:** Azure Managed Prometheus + Managed Grafana (or kube-prometheus-stack). **Logs:** Container Insights / Log Analytics.
- **SLOs:** for example API availability 99.9% over 30 days and p95 latency < 300 ms. Alert on
  error-budget burn rate (fast: 14.4x over 1h; slow: 6x over 6h), not on raw CPU.
- **Alert routing:** sev1 pages on-call, sev2 creates a ticket or Slack message. Every alert links a runbook.
- **Backup / DR:** GRS storage in prd, blob versioning and soft delete, Key Vault soft delete + purge protection,
  versioned Terraform state. IaC is the recovery plan for stateless resources, so rehearse it (rebuild dev from
  scratch). Define RPO/RTO per service and run restore drills; "backups exist" is not evidence.
- **Incident response:** severity definitions, incident commander role, one comms channel, blameless
  post-mortem with tracked actions, and a game day that includes losing a zone.
- **Pipeline observability:** every plan is stored as a run artifact and job summary, giving an audit trail
  of who approved which change.
