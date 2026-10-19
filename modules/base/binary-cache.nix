# This repo's own attic binary cache (served by the `attic` host). Every
# host imports it except attic itself.
{
  flake.modules.nixos.binary-cache = {
    nix.settings = {
      substituters = [ "https://attic.a5f.org/system" ];
      trusted-public-keys = [ "system:JKldX37z2mGGfjceZeMLKpWdqwE08gE0ddVUwRJ2R3A=" ];
    };
  };
}
