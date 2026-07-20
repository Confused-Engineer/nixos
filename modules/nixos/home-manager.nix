# Home-Manager wiring (was mkSystem's useHomeManager block). Included only by
# the hosts that want HM (desktop, laptop).
#
# `flakeConfig` closes over the flake-parts config so we can hand the
# dendritic HM modules (`flake.modules.homeManager.{custom,david}`) to the
# user's home. `hostname` is derived from the host's own networking.hostName,
# reproducing the old `extraSpecialArgs.hostname`.
{ config, ... }:
let
  flakeConfig = config;
in
{
  flake.modules.nixos.homeManager =
    { config, inputs, ... }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        extraSpecialArgs = {
          inherit inputs;
          hostname = config.networking.hostName;
        };
        users.david.imports = [
          flakeConfig.flake.modules.homeManager.custom
          flakeConfig.flake.modules.homeManager.david
        ];
      };
    };
}
