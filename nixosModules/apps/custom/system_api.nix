{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "system_api";
  version = "dev";

  src = fetchFromGitHub {
    owner = "Confused-Engineer";
    repo = "system_api";
    tag = finalAttrs.version;
    hash = "sha256-tQTNKBDs90WbBtEwnTfQdnBFyz1y6R1Im2gYxerAbQw=";
  };

  cargoHash = "sha256-5QgGQrjHhtdhFDmdl/R8HExObUfGJyZ7oNEK/lVkJAY=";

  meta = {
    description = "System API for basic Home Assistant Commands";
    homepage = "https://github.com/Confused-Engineer/system_api";
    license = lib.licenses.unlicense;
    maintainers = [ "Confused-Engineer" ];
  };
})