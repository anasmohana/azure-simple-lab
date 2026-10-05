# Monitoring / SRE

**Implemented:** Log Analytics workspace (30d, daily cap), Key Vault audit logs shipped to it,
action group (email), metric alert on storage availability < 99%.

**Design for AKS/prod**
- Metrics: Azure Managed Prometheus + Grafana; logs: Container Insights/Log Analytics.
- SLOs: e.g. API availability 99.9% / 30d, p95 latency < 300ms. Alert on **error-budget burn rate**
  (fast: 14.4x over 1h; slow: 6x over 6h), not on raw CPU.
- Alert routing: sev1 pages on-call, sev2 to ticket/Slack. Every alert links a runbook.
- Backup/DR: storage GRS (prd) + blob versioning/soft delete; Key Vault soft delete + purge protection;
  state storage versioned. IaC is the DR plan for stateless pieces, so test it: rebuild dev from scratch quarterly.
  Define RPO/RTO per service and run a restore drill, not just "backups exist".
- Incident response: severity definitions, incident commander, comms channel, blameless post-mortem with tracked actions.
