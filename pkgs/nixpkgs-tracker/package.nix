{
  lib,
  fetchFromGitHub,
  rustPlatform,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  wayland,
  libxkbcommon,
  libx11,
  libxcursor,
  libxi,
  libxrandr,
  vulkan-loader,
  libGL,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "nixpkgs-tracker";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "Confused-Engineer";
    repo = "nixpkgs-tracker";
    tag = finalAttrs.version;
    hash = "sha256-Sr6GWkgIFJP9f2H7KL3CrRpqIIYw+f6PNAHcXfrAqx0=";
  };

  cargoHash = "sha256-AJPF+ocswUmErV0S9whgGSKFrmGEX9CHfMDwaO95Gi0=";

  nativeBuildInputs = [
    makeWrapper
    copyDesktopItems
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "nixpkgs-tracker";
      desktopName = "nixpkgs Tracker";
      exec = "nixpkgs-tracker";
      icon = "nixpkgs-tracker";
      comment = "Track nixpkgs package versions across stable, unstable and master";
      categories = [
        "Development"
        "Utility"
      ];
      terminal = false;
      # Lets the desktop match the running window back to this entry, so the
      # icon shows in the dock as well as the launcher.
      startupWMClass = "nixpkgs-tracker";
    })
  ];

  postInstall = ''
    install -Dm444 assets/logo.png \
      $out/share/icons/hicolor/256x256/apps/nixpkgs-tracker.png
  '';

  # eframe loads its windowing and graphics libraries with dlopen rather than
  # linking them, so they have to be resolvable at runtime.
  runtimeLibraryPath = lib.makeLibraryPath finalAttrs.passthru.runtimeLibs;
  postFixup = ''
    wrapProgram $out/bin/nixpkgs-tracker \
      --prefix LD_LIBRARY_PATH : "$runtimeLibraryPath"
  '';

  passthru.runtimeLibs = [
    # Wayland + input
    wayland
    libxkbcommon
    # X11 / XWayland fallback
    libx11
    libxcursor
    libxi
    libxrandr
    # wgpu prefers Vulkan, with GL as a fallback
    vulkan-loader
    libGL
  ];

  meta = {
    description = "Track nixpkgs package versions across stable, unstable and master";
    longDescription = ''
      A GUI for watching packages across NixOS stable, unstable and master.
      Stable and unstable versions come from the search.nixos.org Elasticsearch
      backend; master versions are resolved by evaluating the current master
      HEAD, which requires `nix` on PATH at runtime (always the case on NixOS).
    '';
    homepage = "https://github.com/Confused-Engineer/nixpkgs-tracker";
    license = lib.licenses.unlicense;
    maintainers = [ "Confused-Engineer" ];
    platforms = lib.platforms.linux;
    mainProgram = "nixpkgs-tracker";
  };
})
