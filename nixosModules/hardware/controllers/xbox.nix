{ lib, pkgs, config, ... }:
with lib;                      
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.custom.hardware.controllers;
in {
  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.custom.hardware.controllers = {
  
    xbox = {
      enable = mkEnableOption "Provide Xbox Controller Support";
    };



  };
  # Define what other settings, services and resources should be active IF
  # a user of this "hello.nix" module ENABLED this module 
  # by setting "services.hello.enable = true;".
  config = mkIf cfg.xbox.enable {

    hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings.General = {
          experimental = true; # show battery

          # https://www.reddit.com/r/NixOS/comments/1ch5d2p/comment/lkbabax/
          # for pairing bluetooth controller
          Privacy = "device";
          JustWorksRepairing = "always";
          Class = "0x000100";
          FastConnectable = true;
        };
      };
      services.blueman.enable = true;

      hardware.xpadneo.enable = true; # Enable the xpadneo driver for Xbox One wireless controllers

      boot = {
        extraModulePackages = with config.boot.kernelPackages; [ xpadneo ];
        extraModprobeConfig = ''
          options bluetooth disable_ertm=Y
        '';
        # connect xbox controller
      };

  };
}