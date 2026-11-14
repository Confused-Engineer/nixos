# Hookshot: native PC port of Ocarina of Time (Switch 2). The AppImage is the
# *builder*: it ships its own Python/Tk, clang, emsdk and a glibc 2.35 sysroot,
# and compiles the game from the user's own .nup dump into ~/Games/Hookshot.
# The built game is a generic-Linux binary, so start it through this wrapper
# (`hookshot --play`, or the desktop entry's Play action), which runs it inside
# the same FHS env instead of bare NixOS.
{
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "hookshot";
  version = "2.2.0-rc.1";

  src = fetchurl {
    url = "https://git.notrexed.dev/Hookshot/Hookshot/releases/download/v${version}/Hookshot-v${version}-x86_64.AppImage";
    hash = "sha256-BdMBV55b1l5qaOO3ncCxxBWYp7v4V5UwOxUMXiwfQG0=";
  };

  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # The game's audio/input/video deps beyond the default AppImage set.
  extraPkgs =
    pkgs: with pkgs; [
      pipewire
      libdecor
      libxkbcommon
      wayland
    ];

  # AppRun writes $APPIMAGE (else its own, GC-able store path) into the built
  # game's hookshot_version.txt as `builder=`; the in-game update offer runs
  # that with `--update`. Point it at the stable system wrapper instead.
  profile = ''
    # With no GDK_SCALE/Xft.dpi (COSMIC sets neither) the builder scales its
    # UI by XWayland's screen height / 1080, and that height spans every
    # monitor (2560 px here, portrait side screens) -> a ~2.4x zoomed window.
    # Default to 1x; set HOOKSHOT_UI_SCALE yourself to override.
    export HOOKSHOT_UI_SCALE="''${HOOKSHOT_UI_SCALE:-1}"
    if [ -x /run/current-system/sw/bin/hookshot ]; then
      export APPIMAGE=/run/current-system/sw/bin/hookshot
    fi
  '';

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/hookshot-builder.desktop \
      $out/share/applications/hookshot.desktop
    substituteInPlace $out/share/applications/hookshot.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=hookshot'
    install -Dm444 ${appimageContents}/usr/share/icons/hicolor/256x256/apps/hookshot.png \
      $out/share/icons/hicolor/256x256/apps/hookshot.png
  '';

  meta = {
    description = "Native PC port of Ocarina of Time (Switch 2), built from your own copy of the game";
    homepage = "https://git.notrexed.dev/Hookshot/Hookshot";
    changelog = "https://git.notrexed.dev/Hookshot/Hookshot/releases/tag/v${version}";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "hookshot";
  };
}
