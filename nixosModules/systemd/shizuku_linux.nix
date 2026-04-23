{ lib, pkgs, config, ... }:                     
let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.custom.systemd.shizukuLinux;
in {
  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.custom.systemd = {
  
    shizukuLinux = {
      enable = lib.mkEnableOption "Setup shizuku_linux on device plugin";
    };


  };
  # Define what other settings, services and resources should be active IF
  # a user of this "hello.nix" module ENABLED this module 
  # by setting "services.hello.enable = true;".
  config = lib.mkIf cfg.enable {

    networking.firewall.allowedTCPPorts = [ 5002 ]; # Allow TCP port 80


    nixpkgs.config.packageOverrides = pkgs: {
      shizuku_linux = pkgs.callPackage ./../apps/custom/shizuku_linux.nix { };
    };

    environment.systemPackages = with pkgs; [
      shizuku_linux
    ];

    programs.adb.enable = true;

    systemd.services.shizuku_linux = {
      enable = true;
      description = "Start Shizuku on Device Plugin";
      wantedBy = [ "network.target" ];
    # after = [ "network.target" ];
      serviceConfig = {
      # ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
        ExecStart = "${pkgs.shizuku_linux}/bin/shizuku_linux";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}