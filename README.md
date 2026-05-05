# nixos

Multi-machine NixOS configuration. One flake, three hosts: `desktop`, `laptop`, `kodi`.

## Layout

```
.
├── flake.nix                 # entry point — defines hosts via mkSystem
├── lib/                      # shared helpers (e.g. NVIDIA suspend fix)
├── pkgs/                     # custom packages (overlay)
│   ├── default.nix
│   ├── jellyfin2samsung/
│   ├── shizuku-linux/
│   ├── system-api/
│   └── vintagestory/
├── users/
│   └── keys.nix              # authorized SSH keys, single source
├── homeManager/
│   └── david.nix             # shared HM config
├── machines/
│   ├── baseline.nix          # imported by every host
│   ├── desktop/
│   ├── laptop/
│   └── kodi/
└── nixosModules/             # custom NixOS modules under `custom.*`
    ├── apps/
    ├── boot/
    ├── hardware/
    ├── home-manager/         # HM-side custom modules
    ├── os/
    ├── systemd/
    └── templates/
```

## Conventions

- **Custom options live under `custom.*`.** Each module declares one
  subtree (`custom.apps.steam`, `custom.os.ui.cosmic`, …) and one `cfg`
  binding scoped to *that* subtree, not its parent.
- **`pkgs/` holds derivations, `nixosModules/` holds modules.** A file
  with `options` + `config` blocks is a module; a file with a build
  expression is a package. They go in different trees.
- **Anything duplicated across modules belongs in `lib/`.** Currently
  that's only `mkNvidiaSuspendFix`, but the directory is the home for
  any future helpers.

## Building

```bash
sudo nixos-rebuild switch --flake .#$(hostname)
```

Or pull straight from GitHub on any host:

```bash
sudo nixos-rebuild switch --flake github:Confused-Engineer/nixos#desktop --refresh
```

## Adding a new custom package

1. Drop `pkgs/<name>/package.nix` with a `callPackage`-able derivation.
2. Add one line to `pkgs/default.nix`:
   ```nix
   <name> = final.callPackage ./<name>/package.nix { };
   ```
3. Reference as `pkgs.<name>` from any module — no `packageOverrides`
   needed.

## Adding a new module

1. `nixosModules/<area>/<name>/default.nix` declaring `options.custom.<area>.<name>`.
2. Append `./<area>/<name>` to `nixosModules/default.nix`'s `imports` list.
3. Set `custom.<area>.<name>.enable = true;` from the host that wants it.

## CI

`.github/workflows/flake-update.yml` runs weekly: updates `flake.lock`,
builds all three hosts in parallel as a smoke test, and pushes the lock
update to `main` only if every host built. Manual run via
`workflow_dispatch`.
