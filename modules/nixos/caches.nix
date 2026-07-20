# Binary-cache substituters, one named module each so hosts opt in explicitly.
# Was mkSystem's `useBinaryCache` / `useCudaCache` booleans.
{
  flake.modules.nixos.binaryCache = {
    nix.settings = {
      substituters = [ "https://attic.a5f.org/system" ];
      trusted-public-keys = [ "system:OYIcW3XGdarzUi63x+H5mJ4FIhiYZcdiNUdyL7mKKEE=" ];
    };
  };

  flake.modules.nixos.cudaCache = {
    nix.settings = {
      substituters = [ "https://cuda-maintainers.cachix.org" ];
      trusted-public-keys = [
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };
  };
}
