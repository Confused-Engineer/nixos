{ lib, pkgs, config, ... }:
with lib;                      
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.custom.os.autoUpgrade;
in {
  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.custom.os = {
  
    autoUpgrade = {
      enable = mkEnableOption "Garbage Collect";
    };


  };
  # Define what other settings, services and resources should be active IF
  # a user of this "hello.nix" module ENABLED this module 
  # by setting "services.hello.enable = true;".
  config = mkIf cfg.enable {

  system.autoUpgrade = {
      enable = true;
      flake = "/etc/nixos";
      flags = [
        "--update-input"
        "nixpkgs"
       # "--no-write-lock-file"
        "-L" # print build logs
      ];
      allowReboot = false;
      operation = "boot";
      dates = "daily"; # UTC = 5am EST
    };
    
  };
}