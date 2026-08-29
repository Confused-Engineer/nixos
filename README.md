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
│   ├── attic/                 # atticd binary cache, cloned from server-template
│   ├── kodi/
│   ├── server-template/      # disko-partitioned Proxmox VM template
│   ├── controller/            # container host cloned from server-template
│   ├── music-assist/          # container host cloned from server-template
│   ├── dns1/                  # Blocky DNS resolver, cloned from server-template
│   └── dns2/                  # Blocky DNS resolver, cloned from server-template
└── nixosModules/             # custom NixOS modules under `custom.*`
    ├── apps/                 # desktop/user-facing apps (Firefox, Steam, ...)
    ├── hardware/             # physical-hardware modules (GPU, controllers)
    ├── os/                   # boot, desktops (de-*), gc, settings-*
    ├── systemd/
    └── virtualization/       # Proxmox/VM/container-only modules: proxmox-vm.nix
                               # (disko + VM hardware, imported per-host, not
                               # registered centrally — see its header comment),
                               # container-host.nix, blocky.nix
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

## Installing `server-template` (Proxmox VM)

`server-template` is a disko-partitioned Proxmox VM template — stable NixOS,
no home-manager, SSH-key-only login. Installed from the NixOS ISO's CLI,
not `nixos-rebuild`.

**In Proxmox first:** BIOS = OVMF (UEFI) with an EFI disk added, machine
type `q35`, SCSI controller `VirtIO SCSI single`, disk bus **SCSI** (so it
shows up as `/dev/sda`), QEMU Guest Agent enabled in Options, NixOS
minimal ISO attached. Give the VM **at least 4GB RAM** for the install —
the live ISO's root is a RAM-backed tmpfs, and evaluating this flake
fetches several inputs (`nixpkgs`, `nixpkgs-unstable`, `home-manager`,
etc.) into the store before it can build anything, which a 1–2GB installer
VM will run out of room for (`error: writing to file: No space left on
device`). You can lower the VM's RAM back down after install, once it's
running off the real disk.

Boot the ISO, then:

```bash
# 1. Become root, confirm networking (DHCP should just work)
sudo -i
ip a

# 2. Partition, format, and mount /dev/sda per disko.nix — DESTROYS existing data on sda
export NIX_CONFIG="experimental-features = nix-command flakes"
nix run github:nix-community/disko/latest -- \
  --mode disko \
  --flake 'github:Confused-Engineer/nixos#server-template'

# 3. Install the system (pulls the flake from GitHub, builds, installs to /mnt)
nixos-install --flake 'github:Confused-Engineer/nixos#server-template' --no-root-passwd

# 4. Reboot into the new system — remove the ISO from the VM first
reboot
```

After first boot, SSH in as `david` (password auth is disabled, so this or
the Proxmox console is the only way in), confirm `qemu-guest-agent` is
reporting (`systemctl status qemu-guest-agent`, check the IP shows under
the VM's Summary tab in Proxmox), then shut the VM down and convert it to
a template (right-click → **Convert to Template**).

Clones made from the template keep the `server-template` hostname/config
until either given Proxmox cloud-init metadata (Cloud-Init tab on the
clone) or rebuilt onto their own flake host entry.

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
