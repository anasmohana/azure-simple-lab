# 30-minute walkthrough
- 5 min  Architecture: README diagram; "a lab implementing the patterns I use in production."
- 10 min GitHub Actions + Terraform: terraform.yml, apply.yml, the five layers (bootstrap, network, runner, aks, aks-bootstrap): common + dev/prd roots, state per layer per env. Talk: OIDC vs long-lived
         secrets (federated credential subject pinned to repo+environment), remote state + blob-lease locking,
         env separation (state key, GitHub Environments, approval on prd), pinned providers and module SHAs,
         plan review in the run summary, apply re-plans (never applies stale plans), concurrency group per env, drift.
- 5 min  Real Azure: show resource group in portal created by the pipeline run.
- 5 min  AKS design + k8s/ manifests + docs/SRE.md. "Not provisioned: no reason to pay for an idle cluster."
- 5 min  docs/REVIEW-FINDINGS.md: the first three risks I'd report; how I audit environments; questions.
