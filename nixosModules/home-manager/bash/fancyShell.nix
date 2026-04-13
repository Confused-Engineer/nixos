{ config, pkgs, ... }:
{
  programs.bash = {
    enable = true;
    initExtra = ''
      export PS1='\[\e[38;5;76m\]\u\[\e[0m\] in \[\e[38;5;32m\]\w\[\e[0m\] \\$ '
      nitch
    '';
  };
  home.packages = with pkgs; [
    nitch
  ];
}