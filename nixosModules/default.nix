
{ config, pkgs, lib, ... }:

{

    imports = [
        ./apps/gaming/steam.nix
        ./apps/gaming/steamSystemd.nix
    ];

}