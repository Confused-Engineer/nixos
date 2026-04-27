{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "system_api";
  version = "v0.1.1";

  src = fetchFromGitHub {
    owner = "Confused-Engineer";
    repo = "system_api";
    tag = finalAttrs.version;
    hash = "sha256-3/S5V36lNix3iF+7DI6F/pVFhpzUbO9Gi1c9T1CEqGc=";
  };

  cargoHash = "sha256-76S9hrMuc2YlrgzuKYR7AohH+rTxo4727tw0QfS6rBo=";

  meta = {
    description = "System API for basic Home Assistant Commands";
    homepage = "https://github.com/Confused-Engineer/systemAPI";
    license = lib.licenses.unlicense;
    maintainers = [ "Confused-Engineer" ];
  };
})