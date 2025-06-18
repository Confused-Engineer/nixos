
{ config, pkgs, lib, ... }:

{

    imports = [
        ./apps/gaming/steam.nix
        ./apps/gaming/steamSystemd.nix
        ./services/system_api.nix
        ./os/autoclean.nix
    ];

}