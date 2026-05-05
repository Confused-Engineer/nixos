# Copy-paste starting point for a new Rust package. Not imported anywhere —
# the leading underscore on the filename keeps it out of any glob.
#
# To use:
#   1. Copy to `pkgs/<name>/package.nix`.
#   2. Replace `pname`, `version`, `src`, and the two hashes.
#   3. Run `nix build` once with placeholder hashes to get the real ones.
#   4. Add an entry to `pkgs/default.nix`.

{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ripgrep";
  version = "14.1.1";

  src = fetchFromGitHub {
    owner = "BurntSushi";
    repo = "ripgrep";
    tag = finalAttrs.version;
    hash = "sha256-gyWnahj1A+iXUQlQ1O1H1u7K5euYQOld9qWm99Vjaeg=";
  };

  cargoHash = "sha256-9atn5qyBDy4P6iUoHFhg+TV6Ur71fiah4oTJbBMeEy4=";

  meta = {
    description = "Fast line-oriented regex search tool, similar to ag and ack";
    homepage = "https://github.com/BurntSushi/ripgrep";
    license = lib.licenses.unlicense;
    maintainers = [ ];
  };
})