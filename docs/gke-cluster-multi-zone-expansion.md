# GKE cluster multi-zone (AZ) expansion

Goal: document how growing a GKE cluster's node footprint from one zone to
two (or more) works mechanically, why it's an in-place operation rather
than a destroy/recreate, and what has to be handled first across this
repo before it's safe to flip on. Companion to
`docs/clickhouse-ha-migration.md`, which covers the ClickHouse-specific
replication work gated behind this.

## Current state (as of 2026-07-02)

- `modules/gke/main.tf`: `google_container_cluster.default` is a **zonal**
  cluster — `location = var.azs[0]`. No `node_locations` is set anywhere
  on the cluster, so nodes are implicitly confined to that single zone.
- `azs` is already a list end-to-end (`module.networking.azs`, driven by
  `var.provider_azs` or dynamic zone discovery via
  `data.google_compute_zones.available`), but only `azs[0]` is consumed
  anywhere today. Example deployments currently set
  `provider_azs = ["us-central1-a"]` — a single zone.
- Four `google_container_node_pool` resources exist: `default`,
  `ch_node_pool`, `custom_node_pools` (for_each). None set their own
  `node_locations` except `ch_node_pool`, which is now pinned to
  `[var.azs[0]]` as a guard against the change this doc describes (it's a
  no-op today, a guardrail once the cluster spans zones).
- Two other resources hardcode `azs[0]` outside the `gke` module:
  `volumes.tf`'s `redis_data` (zonal PD) and
  `modules/load_balancer/neg.tf`'s standalone NEG (`zone = var.azs[0]`).

## Two different things people mean by "cluster HA"

Worth separating up front since they have very different blast radii and
costs:

1. **Node-level / worker HA** — spreading a node pool's compute across
   multiple zones so a single-zone outage doesn't take out all workers.
   This is what `node_locations` controls. Doesn't touch the control
   plane. This is what "expand the AZs" means in this doc.
2. **Control-plane HA** — replicating the GKE master itself across zones,
   so the API server survives a zone outage. That means the cluster
   becomes *regional* instead of *zonal* — the `location` field changes
   from a zone to a region. Google's own terminology calls a zonal
   cluster with multi-zone nodes a "multi-zonal cluster," which is easy to
   confuse with a "regional cluster" — they are not the same thing.

## How the node-level operation works

`node_locations` is a plain `(Optional)` attribute on both
`google_container_cluster` and `google_container_node_pool` in the
`hashicorp/google` provider — **not** `ForceNew`. Confirmed against the
provider source docs:

> `node_locations` - (Optional) The list of zones in which the cluster's
> nodes are located. Nodes must be in the region of their regional
> cluster or in the same region as their cluster's zone for zonal
> clusters. **If this is specified for a zonal cluster, omit the
> cluster's zone.**
> — `google_container_cluster` docs

> The list of zones in which the node pool's nodes should be located.
> [...] If unspecified, the cluster-level `node_locations` will be used.
> — `google_container_node_pool` docs (same field name, per-pool override)

Two consequences that are easy to get wrong:

- Setting this field produces an in-place Terraform update (`~`), not a
  replace (`-/+`). GKE applies it as a live locations update — the same
  mechanism as `gcloud container clusters update --node-locations=...`.
- For our zonal cluster (`location = var.azs[0]`), the value to set is
  **just the additional zone(s)**, not `[azs[0], azs[1]]` — the master's
  own zone is implicit and should be omitted per the doc note above:
  ```hcl
  node_locations = [var.azs[1]]
  ```
- A pool's own `node_locations` **fully overrides** the cluster-level
  list for that pool — it doesn't merge with it. That's what makes the
  `ch_node_pool` pin a hard guarantee rather than a default that can be
  drifted away from.

### What actually happens operationally

Setting `node_locations` on the cluster changes where **new** nodes can
be created for any pool that doesn't set its own override. GKE doesn't
relocate existing nodes the moment the field changes — it starts placing
new nodes (from resizes, upgrades, or pool recreation) in the added
zone(s). Because every node pool here sets
`autoscaling.location_policy = "ANY"`, the autoscaler will actively
(re)balance nodes across the available zones over time, not only on the
next manual resize — so "nothing moves immediately" is true at apply
time, not indefinitely after. No cluster or node-pool recreation, no
downtime for workloads already running in `azs[0]`.

## What has to happen first

1. **Pin every stateful pool that owns a zonal disk** — otherwise the
   autoscaler will eventually rebalance it onto a zone its disk can't
   attach to, and it'll fail silently until something tries to
   reschedule.
   - `ch_node_pool` — **done**. Pinned to `[var.azs[0]]` in
     `modules/gke/main.tf`, matching the zone of `clickhouse_data` /
     `clickhouse_logs` (`volumes.tf`).
   - Redis — **not done**. `redis_data` (`volumes.tf`) is also a zonal PD
     in `azs[0]`, but Redis runs on the shared `default` pool, which has
     no pin. Needs either a dedicated pinned pool (mirroring the
     `ch_node_pool` pattern) or a k8s-level zone constraint
     (`nodeSelector` / topology-aware PVC binding) — Terraform can't
     scope a single pod's placement within a shared pool on its own.
2. **Standalone NEG** (`modules/load_balancer/neg.tf`) is hardcoded to
   `zone = var.azs[0]` for the nginx backend. Once the `default` pool can
   schedule into the new zone, endpoints there won't be represented in
   this NEG unless a second per-zone NEG is created and wired into the
   backend service.
3. **Decide the rollout mechanism.** `azs` already carries whatever zone
   list a deployment configures (`provider_azs`), but nothing consumes
   more than `azs[0]` today. Given this repo backs "many clusters
   deployed to a single AZ," prefer a per-cluster, explicit opt-in
   (e.g. only widen `node_locations` where the deployment's `azs` list
   has more than one entry) over a blanket default change to the shared
   module — so this can be validated on one cluster before it touches the
   rest of the fleet.

## Non-goal: control-plane HA

If what's actually wanted is "the cluster survives a zone outage
including the API server," that's the control-plane HA case above, not
this one — it means changing `location` from a zone to a region. That
field is effectively immutable for an existing cluster in this provider;
converting a running zonal cluster to regional is not an in-place
Terraform operation and, as far as this repo's tooling goes, means
standing up a new cluster rather than updating the existing one. Worth
flagging explicitly, since "expand the AZs" is ambiguous between the two
and only one of them is safe to do live.

## Rollout sequence

1. Pin ClickHouse — done, deploy independently (no-op today).
2. Pin/handle Redis — open item above, deploy independently.
3. Add a per-zone NEG for the nginx backend — deploy independently.
4. On one cluster, add `node_locations = [var.azs[1]]` to
   `google_container_cluster.default` → `terraform plan` should show
   `~ update in-place`, never `-/+`. Deploy, then confirm the autoscaler
   actually places nodes in the new zone and that stateful pods stay put.
5. Roll out to the rest of the fleet once the pattern is validated.

`docs/clickhouse-ha-migration.md` covers what ClickHouse itself needs
(replicated table engines, a Keeper quorum, per-replica zonal disks)
before *it* can safely span zones — step 1 above (the pin) is a
prerequisite for that plan, not a substitute for it.
