# atticd setup — attic2

Runbook for bringing up the new Attic binary-cache server that will replace the
current `attic` host (10.87.6.55). Decisions baked in: **reuse the old server's
JWT signing key** (existing client tokens keep working) and **start with an empty
store** (caches repopulate as clients push).

## Architecture

- `atticd` serves **plain HTTP on :8080**. TLS for `https://attic.a5f.org` is
  terminated by an **external reverse proxy** (there is no nginx/caddy/ACME in
  this repo — same as the old `attic` host).
- NAR/chunk **storage** lives on a dedicated ext4 disk at **`/mnt/attic`**.
- **Postgres** holds cache metadata on the root disk.
- Host: `attic2`, static IP `10.87.6.56`, firewall opens `8080`.

## 1. Config in this repo (already applied)

`machines/attic2/configuration.nix`
- `services.atticd` enabled, `environmentFile = /etc/atticd.env`.
- `settings.storage = { type = "local"; path = "/mnt/attic"; }`.
- `systemd.services.atticd.serviceConfig.ExecStartPre` chowns `/mnt/attic` to the
  DynamicUser on every start.
- Postgres `atticd` DB, firewall `8080`, `nix.settings.trusted-users` includes
  `david`.

`machines/attic2/data-mounts.nix` — mounts `/mnt/attic`.
`flake.nix` — `attic2` wired with `useHomeManager = false`, `useBinaryCache = false`.

> ⚠ **Verify the disk UUID.** `data-mounts.nix` was copied from the desktop and
> reuses `279be7a7-…`. On attic2 run `lsblk -f` / `sudo blkid` and confirm the
> UUID of the real `/mnt/attic` disk, then fix it if it differs — otherwise the
> mount silently no-ops (`nofail`) and atticd writes to the root filesystem.

## 2. JWT secret — reuse attic's key

Copy the env file **verbatim** from the old host so tokens signed there keep
validating here:

```bash
# on attic (.55): print it (or scp the file)
sudo cat /etc/atticd.env

# on attic2 (.56): write it root-only
sudo tee /etc/atticd.env >/dev/null <<'EOF'
ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=<same value as attic>
EOF
sudo chmod 600 /etc/atticd.env
```

The service asserts this file exists; a fresh box has no `/etc/atticd.env`, so do
this **before** the first rebuild (or the switch fails the assertion).

## 3. Deploy

On the box:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#attic2
```

Or remotely from your workstation:

```bash
nixos-rebuild switch --flake /etc/nixos#attic2 \
  --target-host root@10.87.6.56 --build-host localhost
```

## 4. Verify

```bash
systemctl status atticd
journalctl -u atticd -e
ls -ld /mnt/attic          # should be owned by atticd:atticd, mode 0750
curl -sS http://localhost:8080/   # atticd responds
```

## 5. Create the `system` cache

The fresh Postgres has **no caches yet**. Mint an admin token (see §6), log in,
and create the cache:

```bash
attic login attic2 http://localhost:8080 <admin-token>
attic cache create system
attic cache configure system --retention-period '2 weeks'   # optional
```

> If you still hold your old admin token, it already validates here (shared key)
> — skip `make-token` and just `attic login` with it.

Smoke test:

```bash
attic push system $(which hello)
```

> **Upstream filtering (already on by default).** A new cache defaults to
> `--upstream-cache-key-name cache.nixos.org-1`, so `attic push` automatically
> **skips any path signed by cache.nixos.org** — attic only ever stores what
> upstream doesn't have. atticd is *not* a pull-through cache; this filtering is
> a client-side push behavior, so:
> - don't pass `--ignore-upstream-cache-filter` on push (it defeats the point);
> - keep `cache.nixos.org` in clients' substituters (the flake already does —
>   `binaryCache` adds attic *alongside* it). Upstream paths come from
>   cache.nixos.org, your paths from attic.
>
> Verify the filter is set: `attic cache info system` (look for the upstream key).

> ⚠ **Public-key note.** A freshly-created `system` cache generates a **new NAR
> signing keypair**, so its public key is **not** the `system:OYIcW3…` currently
> in `flake.nix`. Read the new one now:
>
> ```bash
> attic cache info system   # shows the public key
> ```
>
> You'll need it at cutover (§7).

## 6. Minting access tokens

Tokens are JWTs signed by the server's RS256 key (shared with old `attic`, so
tokens work on both). Mint them **on attic2** with `atticd-atticadm` (it reads
the key from `/etc/atticd.env`). Permissions are per-cache; grant only what a
consumer needs. Each `--<perm>` flag takes a cache-name pattern — prefer the
exact name `system` over `*`.

**Push-only** (CI / builders that upload but must not delete or reconfigure):

```bash
sudo atticd-atticadm make-token \
  --sub "ci-push" --validity "1y" \
  --push "system"
```

Only uploads to `system`. No `--pull` (can't read), no `--delete`,
`--configure-cache*`, `--create-cache`, or `--destroy-cache` — push can only
*add* paths, never remove or edit. Add `--pull "system"` if the same consumer
also needs to use the cache as a substituter.

**Pull-only** (a plain client that just consumes the cache):

```bash
sudo atticd-atticadm make-token \
  --sub "reader" --validity "1y" \
  --pull "system"
```

**Admin** (full control — keep this one safe; used to create/configure caches):

```bash
sudo atticd-atticadm make-token \
  --sub "admin" --validity "1y" \
  --pull "*" --push "*" --delete "*" \
  --create-cache "*" --configure-cache "*" \
  --configure-cache-retention "*" --destroy-cache "*"
```

Use any token with `attic login <name> https://attic.a5f.org <token>`.

> ⚠ There is **no per-token revocation**. The only way to kill a leaked token
> before its `--validity` expires is to rotate the server's RS256 key, which
> invalidates **every** token at once. So keep validity periods sane and rotate
> CI tokens rather than issuing 10-year ones.

## 7. Cutover (later, when replacing attic)

1. Repoint the external reverse proxy for `attic.a5f.org`: `10.87.6.55` → `10.87.6.56`.
2. In `flake.nix`, set `binaryCache.publicKey` to attic2's `system` key from §5
   (URL `https://attic.a5f.org/system` is unchanged).
3. Redeploy clients so they trust the new key. For a zero-gap transition you can
   list **both** old and new public keys in `trusted-public-keys` until every
   host is migrated, then drop the old one.
4. Decommission the old `attic` host.

## Notes

- Chunking / zstd compression / GC are already tuned in `configuration.nix`.
  **Do not change chunking parameters once data exists** — it wrecks dedup.
- Per-cache retention overrides the global `default-retention-period` via
  `attic cache configure <name> --retention-period <duration>`.
