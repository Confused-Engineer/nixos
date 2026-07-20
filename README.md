[![System Build](https://github.com/Confused-Engineer/nixos/actions/workflows/build.yml/badge.svg)](https://github.com/Confused-Engineer/nixos/actions/workflows/build.yml) [![Update Flake](https://github.com/Confused-Engineer/nixos/actions/workflows/flake-update.yml/badge.svg)](https://github.com/Confused-Engineer/nixos/actions/workflows/flake-update.yml)
# nixos

Multi-machine NixOS configuration. One flake, four hosts: `desktop`, `laptop`,
`kodi`, `attic`. Structured with the **dendritic pattern** — `flake-parts` +
`import-tree`, where every `*.nix` under `modules/` is a flake-parts module and
features register themselves into a shared registry instead of a central
import list.

## First-time setup

Two inputs (`flake-parts`, `import-tree`) are new relative to the pre-dendritic
config, so refresh the lock once (keeps existing pins, adds the two):

```bash
nix flake lock
```

## Layout

```
.
├── flake.nix                     # 3 lines of real logic: mkFlake (import-tree ./modules)
├── modules/                      # every *.nix here is a flake-parts module (auto-imported)
│   ├── flake/
│   │   └── modules-option.nix    # declares flake.modules.<class>.<name> registry
│   ├── nixos/                    # NixOS-side modules
│   │   ├── base.nix              # nixpkgs config + overlays (pkgs.stable, custom pkgs)
│   │   ├── caches.nix            # binaryCache / cudaCache substituters
│   │   ├── common.nix            # locale, tz, audio (graphical hosts)
│   │   ├── baseline.nix          # user, auto-upgrade, fonts (desktop+laptop)
│   │   ├── home-manager.nix      # HM wiring → flake.modules.homeManager.*
│   │   ├── boot.nix              # custom.boot.*  (all custom.* option-modules
│   │   ├── apps/ hardware/ os/   #  merge into one `flake.modules.nixos.custom`)
│   │   └── systemd/
│   ├── home/                     # Home-Manager modules → flake.modules.homeManager.custom
│   │   ├── bash.nix mangohud.nix steam.nix streamcontroller.nix
│   │   └── david.nix             # the shared `david` profile
│   └── hosts/                    # one file per host: builds flake.nixosConfigurations.<host>
│       ├── desktop.nix laptop.nix kodi.nix attic.nix
├── machines/                     # per-host NON-module files (imported by path, not auto-loaded)
│   ├── <host>/hardware-configuration.nix
│   ├── desktop/{data-mounts,steam-os}.nix
│   └── kodi/specialisation-default.nix
├── pkgs/                         # custom packages (one overlay) — unchanged
├── lib/mkNvidiaSuspendFix.nix    # shared helper
└── users/keys.nix               # authorized SSH keys, single source
```

## How it fits together

- **Feature modules** write into `flake.modules.nixos.custom` (or
  `flake.modules.homeManager.custom`). Because the registry leaf is a
  `deferredModule`, every file targeting the same name **merges** into one
  module — so all `custom.*` option-modules become a single `custom` module
  that each host imports. This reproduces the old `imports = [ ./nixosModules ]`
  while letting you add a feature by just dropping a file.
- **Host files** (`modules/hosts/*.nix`) each define
  `flake.nixosConfigurations.<host>` by picking named modules from the registry
  and adding host-specific config inline. This replaces the old `mkSystem`
  helper — the per-host matrix is now explicit:

  | host | nixpkgs | home-manager | binaryCache | cudaCache | extras |
  |------|---------|--------------|-------------|-----------|--------|
  | desktop | unstable | ✓ | ✓ | ✓ | — |
  | laptop  | unstable | ✓ | ✓ | ✓ | dell-latitude-5520 |
  | kodi    | **stable** | ✗ | ✓ | ✓ | — |
  | attic   | **stable** | ✗ | ✗ | ✓ | — |

- **Custom options still live under `custom.*`** and behave identically. Only
  the assembly changed, not the option surface.

## Building

```bash
sudo nixos-rebuild switch --flake .#$(hostname)
```

Or pull straight from GitHub on any host:

```bash
sudo nixos-rebuild switch --flake github:Confused-Engineer/nixos#desktop --refresh
```

## Adding things

- **A custom option/module (nixos):** drop `modules/nixos/<area>/<name>.nix`
  with `{ flake.modules.nixos.custom = { lib, config, ... }: { options...; config...; }; }`.
  No import list to touch — `import-tree` finds it.
- **A Home-Manager module:** same, targeting `flake.modules.homeManager.custom`.
- **A custom package:** drop `pkgs/<name>/package.nix`, add one line to
  `pkgs/default.nix`, reference as `pkgs.<name>`.
- **A new host:** add `modules/hosts/<host>.nix` defining
  `flake.nixosConfigurations.<host>` and pick the named modules it needs.

## CI

`.github/workflows/flake-update.yml` runs weekly: updates `flake.lock`, builds
all four hosts in parallel as a smoke test, pushes the lock update to `main`
only if every host built.
