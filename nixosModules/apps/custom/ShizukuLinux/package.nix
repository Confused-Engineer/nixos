{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "shizuku_linux";
  version = "v0.1.2-dev";

  src = fetchFromGitHub {
    owner = "Confused-Engineer";
    repo = "shizuku_linux";
    tag = finalAttrs.version;
    hash = "sha256-Co2/Z/IR2C3e389zGQ5x7ZtNGHWC0WLBeyQIesDu9Rk=";
  };

  cargoHash = "sha256-4siDkMt4PDyqF/ZpudePzp1vfAPxbv15tChN4PVWB2M=";

  meta = {
    description = "Allows Starting Shizuku On Device Plugin";
    homepage = "https://github.com/Confused-Engineer/shizuku_linux";
    license = lib.licenses.unlicense;
    maintainers = [ "Confused-Engineer" ];
  };

})