[![System Build](https://github.com/Confused-Engineer/nixos/actions/workflows/build.yml/badge.svg)](https://github.com/Confused-Engineer/nixos/actions/workflows/build.yml) [![Update Flake](https://github.com/Confused-Engineer/nixos/actions/workflows/flake-update.yml/badge.svg)](https://github.com/Confused-Engineer/nixos/actions/workflows/flake-update.yml)
# nixos

Multi-machine NixOS configuration in the [dendritic
pattern](https://github.com/mightyiam/dendritic): one flake, sixteen
hosts, where **every `.nix` file under `modules/` is a
[flake-parts](https://flake.parts) module** and is loaded automatically by
[import-tree](https://github.com/vic/import-tree). No file is imported by
path and there are no import lists to keep in sync. A file declares what it
contributes, and hosts pick the features they want by name.

## Layout

```
.
├── flake.nix                 # inputs only — outputs = import-tree ./modules
├── pkgs/<name>/package.nix   # custom packages (plain derivations, auto-discovered)
└── modules/                  # every file here is a flake-parts module
    ├── flake-parts.nix       # enables flake.modules, declares flake.lib, systems
    ├── packages.nix          # overlay exposing pkgs/<name> as pkgs.<name>
    ├── lib/                  # flake.lib helpers (mkNvidiaSuspendFix)
    ├── base/                 # aspects nearly every host takes:
    │                         #   nixpkgs, binary-cache, home-manager
    ├── users/
    │   ├── david.nix         # david's home-manager config (part of the home-manager aspect)
    │   └── ssh-keys.nix      # authorized SSH keys, single source (`config.sshKeys`)
    ├── apps/                 # firefox, flatpak, lact, steam, bash, mangohud, streamcontroller
    ├── hardware/             # controller-xbox, gpu-nvidia
    ├── os/                   # boot, gc, settings-common, settings-baseline, yubikey, de-*
    ├── systemd/              # shizuku-linux, system-api
    ├── virtualization/       # proxmox-vm (+ disko), container-host, blocky, swarm-node
    └── hosts/<host>/         # one directory per machine (see below)
        ├── desktop/  laptop/  g5-5587/  kodi/
        ├── attic/            # atticd binary cache
        ├── server-template/  # disko-partitioned Proxmox VM template
        ├── controller/  music-assist/  terraria/   # container hosts
        ├── dns1/  dns2/      # Blocky DNS resolvers
        ├── opencloud/        # OpenCloud against an external lldap
        ├── hermes/           # Hermes Desktop workstation VM (XFCE + RustDesk)
        └── nixswarm-{1,2,3}/ # Docker Swarm nodes (NFS + keepalived VIP)
```

## How it fits together

- **Aspects.** A feature file publishes one or more modules into the
  `flake.modules.<class>.<name>` registry, e.g. `modules/apps/steam.nix`
  defines both `flake.modules.nixos.steam` and
  `flake.modules.homeManager.steam`. One feature, one file, every class
  it touches.
- **Importing an aspect turns it on.** No `enable` flags. A host lists
  what it wants:
  ```nix
  imports = with self.modules.nixos; [ nixpkgs binary-cache steam gpu-nvidia ... ];
  ```
  The one exception is desktop sessions (`de-cosmic`, `de-gnome`, `de-kde`,
  `de-kodi`). They keep `custom.de-<name>.enable` (default on), because a
  specialisation inherits all of its parent's imports and needs a way to
  switch the session off (see the `steamos` and kodi `desktop`
  specialisations).
- **Options are named after the aspect.** Anything an aspect lets a host
  tune lives under `custom.<aspect>.*`, e.g. `custom.firefox.privacy`,
  `custom.gpu-nvidia.open`, `custom.container-host.engine`,
  `custom.steam.shaderThreads`.
- **A host is a directory.** `modules/hosts/<host>/configuration.nix`
  declares `flake.nixosConfigurations.<host>` (choosing stable `nixpkgs` or
  `nixpkgs-unstable`) and the host module `flake.modules.nixos.<host>`.
  Every other file in that directory (`hardware.nix`, `data-mounts.nix`,
  `steam-os.nix`, `containers.nix`, `home.nix`, …) adds to the same
  `flake.modules.nixos.<host>`, and the module system merges them.
- **Shared values without relative imports.** Inside a module, other
  aspects are `self.modules.<class>.<name>`, helpers are
  `self.lib.<name>`, and SSH keys are the top-level `config.sshKeys.<person>`.
  Flake inputs are in scope as `inputs`, so NixOS and home-manager modules
  need no `specialArgs`.
- **Files import-tree skips.** Only `*.nix` files are loaded, and any path
  containing `/_` is ignored. Use a `_`-prefixed name for a plain Nix file
  that isn't a module. Non-Nix files (e.g. `opencloud.env.example`) can sit
  anywhere.
- **Module order is part of the output.** List options
  (`environment.systemPackages`, `home.packages`, …) merge in module order,
  which changes derivation hashes. The restructure kept every host's
  `toplevel` bit-identical to the pre-dendritic layout. That's why host
  import lists follow a fixed order (base, apps, hardware, os, systemd)
  and why `users/david.nix` defines `home-manager.users.david` directly
  instead of publishing a homeManager aspect. Reordering is harmless but
  will show up as a rebuild.

### Checking a refactor didn't change anything

```bash
# Compare a host's derivation against main; identical paths = identical system.
nix eval --raw .#nixosConfigurations.desktop.config.system.build.toplevel.drvPath
nix eval --raw 'git+file:///etc/nixos?ref=main#nixosConfigurations.desktop.config.system.build.toplevel.drvPath'
```

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

## `hermes` (Hermes Desktop VM)

`modules/hosts/hermes` is a Proxmox VM workstation for running Hermes
Desktop, used remotely over **RustDesk** (public ID servers). XFCE on X11
with autologin to `david`, so RustDesk's system service always has a
session to capture — Wayland can't do unattended RustDesk. Unstable, lean
home-manager (Hermes, vscode, claude-code; not the full `users/david.nix`).
SSH is key-only as `david`; root has no SSH.

**In Proxmox:** same as `server-template`, but give it a real display device
(Display = `Default`/`Standard VGA` or `VirtIO-GPU`, not `none`/serial —
RustDesk captures the X screen, so its resolution is RustDesk's
resolution), 4+ cores, 8GB+ RAM, 40GB+ disk. Install with the
`server-template` procedure, substituting `#hermes` in both commands.

After first boot (SSH in as `david`, or use the Proxmox console):

```bash
passwd                          # replace the provisioning password (vmtest)
systemctl status rustdesk       # the unattended-access service should be running
hermes setup                    # pick a provider / API keys (~/.hermes)
```

Then in the RustDesk window on the VM (Proxmox console, or connect once
with the temporary password): **Settings → Security → Set permanent
password**, and note the VM's RustDesk ID. Neither password lives in this
repo.

## `opencloud` (OpenCloud)

`modules/hosts/opencloud` is a `server-template` clone running **OpenCloud**
(file sync/share) as a native NixOS service, web UI on `:9200`, all user
data on a dedicated second disk. Users and groups come from the
**existing lldap on `10.87.6.10:3890`** (not part of this repo) —
OpenCloud's built-in IDM is disabled and every login/lookup goes to that
directory. Traefik terminates TLS for `opencloud.a5f.org` outside this
repo; the `cloudUrl` / `ldapUri` / `ldapBaseDn` bindings at the top of
`configuration.nix` are the only place those live.

(An earlier version of this host also ran OnlyOffice DocumentServer,
integrated over WOPI for in-browser editing — pulled back out, see the
comment at the top of `configuration.nix` for why. `git log` on that file
has the working config if this comes back via Collabora or similar.)

**In Proxmox:** same as `server-template`, plus a **second SCSI disk** on
the same `VirtIO SCSI single` controller so it lands on `/dev/sdb` (disko
formats it and mounts it at `/var/lib/opencloud`).

Install with the standard `server-template` procedure above, substituting
`#opencloud` in both the `disko` and `nixos-install` commands (disko will
wipe **both** `sda` and `sdb`). On first boot the service crash-loops
until its secrets exist — expected. An annotated template lives at
`modules/hosts/opencloud/opencloud.env.example`. SSH in as root and:

```bash
# 1. In the existing lldap's web UI:
#    - create a user `opencloud` (the read-only bind account) and add it to
#      the `lldap_strict_readonly` group
#    - pick (or create) the user that should be the OpenCloud admin
#    Then grab that user's entryUUID from here, binding as the new account:
ldapsearch -x -H ldap://10.87.6.10:3890 \
  -D "uid=opencloud,ou=people,dc=a5f,dc=org" -W \
  -b "ou=people,dc=a5f,dc=org" "(uid=YOUR_USERNAME)" entryUUID

# 2. OpenCloud secrets — start from the template and fill in the two values
curl -fsSL https://raw.githubusercontent.com/Confused-Engineer/nixos/main/modules/hosts/opencloud/opencloud.env.example \
  -o /etc/opencloud.env
chmod 0600 /etc/opencloud.env
nano /etc/opencloud.env  # OC_LDAP_BIND_PASSWORD, OC_ADMIN_USER_ID
systemctl restart opencloud
```

`OC_ADMIN_USER_ID` is what grants the OpenCloud *Admin* role — every other
lldap user lands as a regular *User* on first login. User/group management
stays in lldap; OpenCloud's own admin UI is read-only against the
directory (`OC_LDAP_SERVER_WRITE_ENABLED=false`).

`opencloud init` runs once on first boot (via `opencloud-init-config`) and
writes the internal service-to-service secrets to
`/etc/opencloud/opencloud.yaml` — back that file up alongside the data
disk; without it a rebuilt host can't read the existing storage.

## Adding a new custom package

1. Drop `pkgs/<name>/package.nix` with a `callPackage`-able derivation.
2. That's it. `modules/packages.nix` picks up every `pkgs/<name>/package.nix`
   automatically, so reference it as `pkgs.<name>` from any module.

## Adding a new aspect (feature)

1. Create `modules/<area>/<name>.nix` (any directory works, since import-tree
   loads it either way):
   ```nix
   {
     flake.modules.nixos.<name> =
       { lib, config, pkgs, ... }:
       {
         # Optional knobs for hosts to set:
         options.custom.<name>.someSetting = lib.mkOption { ... };

         config = { ... };
       };
   }
   ```
   Add `flake.modules.homeManager.<name>` in the same file if the feature
   has a per-user side too.
2. `git add` it. Flakes only see tracked files.
3. Add `<name>` to the `imports` list of each host that wants it.

## Adding a new host

1. Create `modules/hosts/<host>/configuration.nix`. Copy the closest
   existing host. For a server that is usually `modules/hosts/controller/`.
2. Optionally add more files to that directory, each defining
   `flake.modules.nixos.<host> = { ... };`. For a machine with real hardware,
   put the `nixos-generate-config --show-hardware-config` output in
   `hardware.nix`.
3. `git add` it, then `sudo nixos-rebuild switch --flake .#<host>`. Add the
   host to the CI matrix in `.github/workflows/` if it should be built
   daily.

## YubiKey U2F (login/sudo) on `desktop`

The `yubikey` aspect (imported by `desktop`, see
`modules/os/yubikey.nix`) lets a registered YubiKey satisfy
`login`, `sudo`, the COSMIC greeter/lock screen, and polkit prompts
(`pkexec`, GUI "authenticate" dialogs) by touching the key instead of
typing a password.

**Password is always a fallback, in every case.** `pam_u2f` is wired in
as PAM `sufficient`, never `required`: touching the key logs you in
immediately, but if the key is missing, unplugged, unregistered, or the
touch fails/times out, PAM just falls through to the normal password
prompt. There is no configuration here that can lock you out — worst
case, you type your password like before.

Importing the aspect only wires up the PAM stack; it does **not**
register a key. Nothing changes until you actually run the setup below
on the desktop.

### One-time setup (do this when you're ready)

1. Rebuild so the module (and `ykman`/`pamu2fcfg`) are installed:

   ```bash
   sudo nixos-rebuild switch --flake .#desktop
   ```

2. Plug in the YubiKey and confirm it's detected:

   ```bash
   ykman info
   ```

3. Register it for your user. `pamu2fcfg` prompts you to touch the key,
   then prints a line for `~/.config/Yubico/u2f_keys` (this file is
   per-user and is what `pam_u2f` checks on every login/sudo/polkit
   prompt system-wide):

   ```bash
   mkdir -p ~/.config/Yubico
   pamu2fcfg > ~/.config/Yubico/u2f_keys
   ```

4. **Strongly recommended:** register a second, backup key in case the
   first is lost or damaged. Swap keys, then append it to the *same*
   line (the file format is one line per user, keys colon-separated):

   ```bash
   printf ':' >> ~/.config/Yubico/u2f_keys
   pamu2fcfg -n | tr -d '\n' >> ~/.config/Yubico/u2f_keys
   echo >> ~/.config/Yubico/u2f_keys
   ```

5. Test it without logging out — open a new terminal:

   ```bash
   sudo -k && sudo true
   ```

   You should see "Please touch the device" and a green blink; touching
   it authorizes sudo with no password prompt. If you don't touch it
   (or unplug the key), it falls back to asking for your password.

6. Once sudo works, test login/lock-screen the same way (lock the
   session or switch to a VT and back) before relying on it.

Add more PAM service names to `custom.yubikey.pamServices` (e.g. a
screen locker with its own PAM service) if something else should also
accept the key.

## CI

`.github/workflows/flake-update.yml` runs weekly: updates `flake.lock`,
builds all three hosts in parallel as a smoke test, and pushes the lock
update to `main` only if every host built. Manual run via
`workflow_dispatch`.
