# ClickHouse HA migration plan (GKE)

Goal: turn today's single-node ClickHouse deployment into an HA setup on
GCP — replicated tables plus nodes spread across availability zones —
without a bulk export/import of existing data.

This has two independent legs that need to land in order:

1. Convert every table's engine to its `Replicated*` counterpart.
2. Spread the ClickHouse node pool across AZs.

Leg 2 can't happen safely before leg 1 — see "Why zone-spreading breaks
today" below.

## Current state (as of 2026-07-02)

- ClickHouse 25.8, single node, no ZooKeeper/Keeper configured at all
  (`system.zookeeper` doesn't exist, no macros defined).
- `modules/gke/main.tf`: `google_container_cluster.default` is a zonal
  cluster at `var.azs[0]`. The `ch_node_pool` is explicitly pinned to
  `node_locations = [var.azs[0]]`, with a comment noting this guards
  against the cluster's `node_locations` growing to multiple zones later
  (i.e. a broader multi-AZ push for the rest of the cluster) and dragging
  the ClickHouse pool onto a zone its disk can't reach.
- `volumes.tf`: `clickhouse_data` and `clickhouse_logs` are **zonal**
  `google_compute_disk` resources, hardcoded to `module.networking.azs[0]`.
  A zonal PD can only attach to a VM in the same zone, so if the CH pod
  ever got scheduled onto a different zone, its disks simply wouldn't
  attach. That's the failure the `node_locations` pin exists to prevent.
- All 22 real tables + 3 materialized views live in `default` and are all
  MergeTree-family (`MergeTree`, `ReplacingMergeTree`, `SummingMergeTree`,
  `CollapsingMergeTree`). Every one of these has a direct `Replicated*`
  counterpart, so nothing in the schema blocks replication:

  | Engine | Tables |
  |---|---|
  | `MergeTree` | audit_log, customer_audit_log, dimensions, logged_statements, node_sessions, pii_log, timeseries_data, timeseries_ranges |
  | `ReplacingMergeTree` | alembic_version, edges, edges_latest, nodes, nodes_latest, node_metrics, power_bi_report_layouts, reference_events, timeseries |
  | `SummingMergeTree` | invalid_nodes, and the implicit inner table behind `daily_reference_events_by_object` |
  | `CollapsingMergeTree(sign)` | lineage_processing_queue |

  `edges_latest_mv` / `nodes_latest_mv` write `TO` existing tables already
  in this list, so they carry no separate storage. `daily_reference_events_by_object`
  owns its own storage (a `SummingMergeTree`) and needs the same treatment
  as any other table.

## Leg 1: convert tables to Replicated engines

`ALTER TABLE ... MODIFY ENGINE` doesn't exist in ClickHouse — engine is
immutable. The zero-copy path relies on the fact that part files on disk
are format-identical across the whole MergeTree family (plain and
Replicated variants alike):

1. `CREATE TABLE t_new (...same columns/ORDER BY/PRIMARY KEY/TTL...) ENGINE = Replicated<X>MergeTree('/clickhouse/tables/{shard}/t', '{replica}', ...)`
2. `ALTER TABLE t_new ATTACH PARTITION ID 'all' FROM t` — none of these
   tables define `PARTITION BY`, so each is currently one giant partition
   (`'all'`). This attach is a hard-link operation, not a copy — instant
   regardless of table size, no doubling of disk usage.
3. Verify row counts / checksums between `t` and `t_new` match.
4. **Pause writes to `t`.** Because step 2 is a *copy*, not a *move*, `t`
   keeps accepting writes right up until this point — anything written
   into `t` after the ATTACH won't be in `t_new`. This is the part that
   actually needs care in the migration script:
   - Stop the writer(s) (or have them briefly buffer/retry).
   - Re-check row counts; backfill any delta into `t_new` if non-zero.
   - `RENAME TABLE t TO t_old, t_new TO t` — atomic cutover, this is what
     readers/writers actually hit afterward.
   - Resume writers.
   The window that matters is only the pause-verify-rename-resume span,
   which is short and constant-time — not proportional to table size.
5. Validate against `t` (now the Replicated table), then `DROP TABLE t_old`.
   Only at this point do the hard-linked files that are no longer
   referenced get freed — until the drop, storage is transiently
   double-referenced (not double-copied).

Two tables briefly "owning" the same partition data during steps 2-4 is
expected, not a hazard: ClickHouse implements the attach via hard links,
so both tables have independent, valid metadata pointing at shared bytes.
The correctness risk is purely logical (writes landing in the wrong table
during the window), not physical (no corruption risk from the shared
files) — hence the write-pause requirement above.

### Prerequisites this exposes

None of these exist yet, locally or in this Terraform repo:

- A Keeper ensemble (`clickhouse-keeper`, not ZooKeeper — 3 nodes for
  quorum).
- Per-pod `{shard}` / `{replica}` macros and a `<remote_servers>` cluster
  definition, so each table's ZK path is consistent across replicas.
- Topology decision: single-shard, N-replica (this is what HA wants here,
  not sharding).

## Leg 2: spreading ClickHouse across AZs

### Why zone-spreading breaks today

The `ch_node_pool` pin to `azs[0]` isn't incidental — it's a direct
consequence of the zonal PDs in `volumes.tf`. Simply widening
`node_locations` on the pool (the way it presumably will happen for the
rest of the cluster) would let GKE reschedule the single CH pod onto a
zone where `clickhouse_data`/`clickhouse_logs` can't attach. There's
exactly one CH replica today, so there's no redundancy to fail over to —
multi-AZ only becomes meaningful once leg 1 gives us multiple replicas
that can each own their own disk.

### Partial mitigation (not real HA, but easy)

Swap `google_compute_disk` (zonal) for `google_compute_region_disk`
(regional, synchronously replicated across 2 zones in-region) for the
single-replica case. This removes the single-zone disk SPOF without
touching ClickHouse at all. Worth knowing the limits before treating it
as sufficient:
- Failover isn't automatic — reattaching to a VM in the surviving zone
  after a zone outage requires a forced attach (`--force-attach` /
  equivalent API call), so this is "faster manual recovery," not
  zero-downtime.
- Regional PDs have roughly half the max IOPS/throughput of a zonal PD of
  the same size/type.
- It doesn't give read/write availability during the outage window, only
  data durability — real HA still needs leg 1.

### Real HA target

Multiple ClickHouse replica pods, each pinned to a **different** zone
with its own zonal PD, kept in sync via the Replicated engines from leg 1,
coordinated by a Keeper quorum (ideally itself spread across zones).

Migration path from current state to that target:

1. Finish leg 1 on the existing single node/zone, backed by a Keeper
   quorum stood up now (bring it up 3-wide across zones from the start —
   no reason to stand up a single-node Keeper and migrate it later).
2. Provision one zonal `google_compute_disk` pair (data+logs) per new
   replica, each in a different target zone.
3. Give each replica its own node pool (or a single pool with
   `node_locations` spanning the target zones plus pod
   affinity/`topology.kubernetes.io/zone` + `WaitForFirstConsumer` PVC
   binding) so a pod always lands in the same zone as its disk. One pool
   per zone is simpler to reason about given the existing `ch_node_pool`
   pattern (taint + dedicated pool per role).
4. Bring up the new replica pods against the same Keeper quorum, same ZK
   path/shard, unique `{replica}` macro each. These start with **empty**
   disks, so ClickHouse will do a genuine network fetch of all data from
   an existing replica to bootstrap them — this is the one place real
   bulk data transfer is unavoidable, but it's a one-time
   per-new-replica bootstrap handled automatically by ClickHouse's
   replication, not a manual export/import.
5. Watch replication lag / `system.replicas` until each new replica is
   caught up, then bring it into serving rotation (client-side load
   balancing or a proxy such as `chproxy`).
6. Only once ≥2 zone-spread replicas are healthy, remove the
   `node_locations = [var.azs[0]]` pin on the original pool (or replace it
   with the per-zone pool arrangement from step 3) — before that point the
   pin still needs to stay, since it's the only thing stopping the
   original single replica from being scheduled somewhere its disk can't
   follow.

### Open items / risks to size before starting

- Cost and ops overhead of running a 3-node Keeper quorum continuously.
- Write topology: ReplicatedMergeTree lets any replica accept writes, but
  simplicity probably wants app writes pinned to one replica (or a proxy)
  rather than fanned out.
- Monitoring: replication lag, Keeper quorum health, per-zone disk usage.
- The write-pause step in leg 1 needs to be scripted/automated (Alembic
  migration) rather than run by hand, since it has to run once per table
  across ~22 tables.
