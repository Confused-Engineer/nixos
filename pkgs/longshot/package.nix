# Longshot: the continuation of Hookshot (Ocarina of Time, Switch 2, as a
# native PC port), by the Hookshot maintainers who moved to MagicBeanDev.
#
# What's packaged is the Longshot *Launcher* (a self-contained .NET/Avalonia
# app). The Longshot repo's own AppImage is only the command-line builder,
# which the launcher downloads, unpacks under ~/.local/share/longshot/launcher
# and runs itself, along with the clang/sysroot/FFmpeg toolchain from
# tools.lock. The builder, its toolchain and the built game are all
# generic-Linux binaries, so they only work as children of this FHS wrapper:
# start the game from the launcher, not from ~/Games/Longshot directly.
{
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "longshot";
  version = "1.0.0-rc.3";

  src = fetchurl {
    url = "https://git.magicbean.dev/MagicBeanDev/LongshotLauncher/releases/download/v${version}/LongshotLauncher-v${version}-x86_64.AppImage";
    hash = "sha256-wbr+G2JcqsQ/Ij7D3hP7WvLqHwUjEvepO6lcKmpsmUs=";
  };

  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs =
    pkgs: with pkgs; [
      # .NET runtime + Avalonia/Skia (dlopen'd by the single-file launcher)
      icu
      openssl
      fontconfig
      dbus
      libdrm
      libgbm
      # the game (SDL2, Vulkan, audio, Wayland)
      vulkan-loader
      pipewire
      libdecor
      libxkbcommon
      wayland
    ];

  # The builder's bundled Python (run by the launcher) has OpenSSL looking for
  # /etc/ssl/cert.pem or hashed /etc/ssl/certs/*.0, neither of which NixOS
  # has, so its HTTPS downloads (DLSS/FSR SDKs, build tools) fail with
  # CERTIFICATE_VERIFY_FAILED.
  profile = ''
    export SSL_CERT_FILE="''${SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}"
  '';

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/longshot-launcher.desktop \
      $out/share/applications/longshot.desktop
    substituteInPlace $out/share/applications/longshot.desktop \
      --replace-fail 'Exec=LongshotLauncher' 'Exec=longshot'
    install -Dm444 ${appimageContents}/longshot-launcher.png \
      $out/share/icons/hicolor/512x512/apps/longshot-launcher.png
  '';

  meta = {
    description = "Launcher that builds and runs Longshot, a native PC port of Ocarina of Time (Switch 2), from your own copy";
    homepage = "https://longshot.magicbean.dev/";
    downloadPage = "https://git.magicbean.dev/MagicBeanDev/LongshotLauncher/releases";
    changelog = "https://git.magicbean.dev/MagicBeanDev/LongshotLauncher/releases/tag/v${version}";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "longshot";
  };
}
