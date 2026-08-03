# CLAUDE.md - terraform-google-datafold

Terraform module for provisioning a Datafold dedicated-cloud deployment on GCP (GKE cluster + supporting infra).

## Per-component cloud identity: not implemented

Unlike the AWS module (`terraform-aws-datafold`, which creates a per-component IRSA role for `server`/`worker`/`dfshell`/`dma`/etc. in `modules/eks/roles.tf`), this repo has **no equivalent per-component GCP service account module**. `modules/gke/iam.tf` only creates a single generic node-pool service account with logging/monitoring/storage roles — there's no `server`/`worker`/`dfshell`/`dma` identity anywhere.

`examples/deployment/infra/config.tf` references `module.gcp.server_role_arn`, `module.gcp.dfshell_service_account_name`, etc. for every component — but `module "gcp"` doesn't exist anywhere in this repo. Treat that example as a dead/aspirational stub (likely copied from the AWS example and never finished), not a working pattern to copy.

**Consequence**: no current GCP dedicated-cloud customer uses Bedrock-equivalent (Vertex AI) or other cloud-identity-gated features — there's no infra to grant them yet. If a GCP customer needs one (e.g. Vertex AI for Thunderbolt/Memgraph), building the per-component Workload Identity SA module here is a prerequisite, not a config toggle. The Helm side (`helm-charts`) already has a dedicated `serviceAccount.gcpServiceAccount` field per component ready to consume a real SA email once this module exists.

## LLM provider gating: not implemented

No Vertex-AI-equivalent to AWS's `k8s_access_bedrock` variable exists (`grep -rn "vertex\|bedrock\|llm"` returns nothing). Would need to be added alongside the per-component SA module above.

## This repo is public

Never reference customer names, deployment names, or account IDs in code, comments, docs, or examples here. Use the established generic placeholder convention instead (see `examples/deployment`, which uses `acme-datafold` as the example deployment name).
