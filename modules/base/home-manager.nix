# Home-manager as a NixOS module. modules/users/david.nix adds david's
# home config to this same aspect. Hosts that want more for david add it
# themselves, e.g. modules/hosts/desktop/home.nix:
#   home-manager.users.david = { ... };
{ inputs, ... }:
{
  flake.modules.nixos.home-manager = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
    };
  };
}
