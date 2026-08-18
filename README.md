[![System Build](https://github.com/Confused-Engineer/nixos/actions/workflows/build.yml/badge.svg)](https://github.com/Confused-Engineer/nixos/actions/workflows/build.yml) [![Update Flake](https://github.com/Confused-Engineer/nixos/actions/workflows/flake-update.yml/badge.svg)](https://github.com/Confused-Engineer/nixos/actions/workflows/flake-update.yml)
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
│   ├── modules/              # HM-side custom modules
│   └── users/
│       └── david.nix         # shared HM config
├── machines/
│   ├── desktop/
│   ├── laptop/
│   ├── g5-5587/
│   ├── attic/
│   ├── kodi/
│   └── server-template/      # disko-partitioned Proxmox VM template
└── nixosModules/             # custom NixOS modules under `custom.*`
    ├── apps/
    ├── hardware/
    ├── os/                   # boot, desktops (de-*), settings-*
    └── systemd/
```

## Conventions

- **Custom options live under `custom.*`, mirroring the file path.** A
  module at `nixosModules/<area>/<name>.nix` declares
  `options.custom.<area>.<name>` and binds one `cfg` to *that* subtree,
  not its parent — e.g. `nixosModules/os/settings-common.nix` owns
  `custom.os.settings-common`, `nixosModules/os/de-cosmic.nix` owns
  `custom.os.de-cosmic`.
- **Every host enables its own baseline.** `custom.os.settings-common`
  (locale, audio, keyboard) and `custom.os.settings-baseline` (the
  `david` user, auto-upgrade, fonts, networking) are opt-in per host
  rather than inherited by import. `kodi` takes only settings-common;
  `attic` takes neither.
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

1. `nixosModules/<area>/<name>.nix` declaring `options.custom.<area>.<name>`.
2. Append `./<area>/<name>.nix` to `nixosModules/default.nix`'s `imports` list.
3. Set `custom.<area>.<name>.enable = true;` from the host that wants it.

## CI

`.github/workflows/flake-update.yml` runs weekly: updates `flake.lock`,
builds all three hosts in parallel as a smoke test, and pushes the lock
update to `main` only if every host built. Manual run via
`workflow_dispatch`.
