---
name: salonx-gates-local
description: "Running salonx's `bun run gates` tier 4 (pgTAP) locally — psql is keg-only, port 5432 is taken by your own postgres"
metadata: 
  node_type: memory
  type: project
  originSessionId: 626cd260-4613-4591-b804-d3be1221ec7f
  modified: 2026-08-08T23:22:39.537Z
---

`bun run gates` (salonx, `scripts/gates.mjs`) skips tier 4 unless `TEST_DATABASE_URL`
is set. Two machine-specific obstacles that CI doesn't have, and that cost 20 minutes
to rediscover on 2026-07-09:

- **`psql` is not on PATH.** It's keg-only Homebrew libpq:
  `export PATH="/opt/homebrew/opt/libpq/bin:$PATH"`. `run-db-tests.sh` shells out to it.
- **Port 5432 is occupied** by your own `postgresql@15`. Boot the throwaway container on
  another port (55432 worked) and point `TEST_DATABASE_URL` at it.
- **Always pass `--tmpfs /var/lib/postgresql/data`.** The `postgres` image declares that path
  as a `VOLUME`, so a run without it mints an anonymous volume (~40–180 MB each). `--rm` clears
  it on a *clean* exit, but any interrupted teardown (Docker Desktop restart, kill, sleep)
  orphans it — that accumulated **101 orphans / 9.2 GB in 6 days** and was pruned 2026-08-08.
  An explicit mount overrides the `VOLUME` directive, so no volume is ever created and there is
  nothing to leak. Verified: `700 postgres` perms, 39 MB used of a 1 GB cap on a fresh initdb.

Full local recipe, mirroring `.github/workflows/test.yml`'s `db-tests` job:

```bash
docker run --rm -d --name probe-db \
  --tmpfs /var/lib/postgresql/data:rw,noexec,nosuid,size=1g \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  -e POSTGRES_USER=postgres -e POSTGRES_DB=postgres -p 55432:5432 postgres:15
bash scripts/migrations/audit-fake-extensions.sh probe-db
bash scripts/migrations/install-pgtap.sh probe-db
docker exec -i probe-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 \
  < scripts/migrations/audit-bootstrap.sql
for f in supabase/migrations/*.sql; do          # ~432 files, ~50s
  head -1 "$f" | grep -q '^-- Squashed into' && continue
  docker exec -i probe-db psql -U postgres -d postgres -q -v ON_ERROR_STOP=1 < "$f"
done
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export TEST_DATABASE_URL="postgres://postgres@localhost:55432/postgres"
bun run gates    # tier 4 runs 212 pgTAP suites in ~50s
```

The tier-3 gates scan the **committed** diff, so a new migration must be committed
before they see it — `gates` warns when it isn't. Ladder verified end-to-end on
2026-07-09; salonx-side details live in `salonx/.claude/skills/tdd-salonx/SKILL.md`
and `salonx/tasks/lessons.md`. See [[salonx-worktree-guard]].
