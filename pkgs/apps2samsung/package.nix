{
  lib,
  buildDotnetModule,
  buildFHSEnv,
  writeShellScript,
  dotnetCorePackages,
  fetchFromGitHub,
  fetchurl,
  esbuild,
  fontconfig,
  freetype,
  libGL,
  libx11,
  libice,
  libsm,
  libxext,
  libxcursor,
  libxi,
  libxrandr,
  libxrender,
  libxinerama,
  libxcomposite,
  libxdamage,
  libxfixes,
  libxtst,
  krb5,
  openssl,
  zlib,
  icu,
  makeDesktopItem,
  nix-update-script,
}:

let
  pname = "apps2samsung";
  version = "2.5.5";

  src = fetchFromGitHub {
    owner = "Apps2Samsung";
    repo = "Apps2Samsung";
    rev = "v${version}";
    hash = "sha256-0tRBId+suQUxUq3c9dFDqNIjNKNdooeqC5e351M6Gj0=";
  };

  tizenSDB = fetchurl {
    url = "https://github.com/PatrickSt1991/tizen-sdb/releases/download/v1.1.0/TizenSdb_v1.1.0_linux-x64";
    hash = "sha256-E5nTGtHMw13IJYJrGNR31fE0OmtbZAKrdES1MV/I0fU=";
  };

  desktopItem = makeDesktopItem {
    name = pname;
    desktopName = "Apps2Samsung";
    comment = "Install any app on Samsung TVs, projectors and smart monitors";
    exec = "${pname} %U";
    icon = pname;
    categories = [
      "Utility"
      "Network"
    ];
    mimeTypes = [ "application/x-apps2samsung" ];
    startupNotify = true;
  };

  apps2samsung-unwrapped = buildDotnetModule {
    pname = "${pname}-unwrapped";
    inherit version src;

    projectFile = "Jellyfin2Samsung-CrossOS/Apps2Samsung.csproj";
    nugetDeps = ./deps.json;

    dotnet-sdk = dotnetCorePackages.sdk_8_0;
    dotnet-runtime = dotnetCorePackages.aspnetcore_8_0;

    executables = [ "Apps2Samsung" ];
    dotnetInstallFlags = [ "-p:PublishSingleFile=false" ];

    postPatch = ''
      substituteInPlace Jellyfin2Samsung-CrossOS/Helpers/AppSettings.cs \
        --replace-fail \
          'Path.Combine(FolderPath, "Assets", "TizenSDB")' \
          'Path.Combine(DataFolderPath, "TizenSDB")' \
        --replace-fail \
          'Path.Combine(FolderPath, "Downloads")' \
          'Path.Combine(DataFolderPath, "Downloads")'

      substituteInPlace Jellyfin2Samsung-CrossOS/Services/ProviderManifestService.cs \
        --replace-fail \
          'Path.Combine(AppSettings.FolderPath, "third-party-apps.cache.json")' \
          'Path.Combine(AppSettings.DataFolderPath, "third-party-apps.cache.json")'

      substituteInPlace Jellyfin2Samsung-CrossOS/Program.cs \
        --replace-fail \
          'var logDir = AppContext.BaseDirectory;' \
          'var logDir = Apps2Samsung.Helpers.AppSettings.DataFolderPath;'

      substituteInPlace Jellyfin2Samsung-CrossOS/Helpers/Core/ProcessHelper.cs \
        --replace-fail \
          'string exeDir = AppContext.BaseDirectory;' \
          'string exeDir = Apps2Samsung.Helpers.AppSettings.DataFolderPath;'

      substituteInPlace Jellyfin2Samsung-CrossOS/Helpers/API/TizenApiClient.cs \
        --replace-fail \
          'Path.Combine(AppContext.BaseDirectory, "Logs",' \
          'Path.Combine(Apps2Samsung.Helpers.AppSettings.DataFolderPath, "Logs",'
    '';

    runtimeDeps = [
      fontconfig
      freetype
      libGL
      libx11
      libice
      libsm
      libxext
      libxcursor
      libxi
      libxrandr
      libxrender
      libxinerama
      libxcomposite
      libxdamage
      libxfixes
      libxtst
      krb5
      openssl
      zlib
      icu
    ];

    postInstall = ''
      mkdir -p "$out/lib/${pname}-unwrapped/Assets/esbuild/linux-x64"
      ln -sf "${esbuild}/bin/esbuild" \
        "$out/lib/${pname}-unwrapped/Assets/esbuild/linux-x64/esbuild"
      rm -rf \
        "$out/lib/${pname}-unwrapped/Assets/esbuild/macos-x64" \
        "$out/lib/${pname}-unwrapped/Assets/esbuild/macos-arm64" \
        "$out/lib/${pname}-unwrapped/Assets/esbuild/win-x64"
    '';
  };
in

buildFHSEnv {
  name = pname;

  targetPkgs = pkgs: with pkgs; [
    apps2samsung-unwrapped
    fontconfig
    freetype
    libGL
    libx11
    libice
    libsm
    libxext
    libxcursor
    libxi
    libxrandr
    libxrender
    libxinerama
    libxcomposite
    libxdamage
    libxfixes
    libxtst
    krb5
    openssl
    zlib
    icu
  ];

  runScript = writeShellScript "${pname}-run" ''
    mkdir -p "''${XDG_CONFIG_HOME:-$HOME/.config}/Apps2Samsung/TizenSDB"
    sdb="''${XDG_CONFIG_HOME:-$HOME/.config}/Apps2Samsung/TizenSDB/TizenSdb_v1.1.0_linux-x64"
    if [ ! -f "$sdb" ]; then
      cp ${tizenSDB} "$sdb"
      chmod +x "$sdb"
    fi
    exec Apps2Samsung "$@"
  '';

  extraInstallCommands = ''
    install -Dm644 ${src}/Jellyfin2Samsung-CrossOS/Assets/jelly2sams.png \
      $out/share/icons/hicolor/256x256/apps/${pname}.png
    install -Dm644 ${desktopItem}/share/applications/${pname}.desktop \
      $out/share/applications/${pname}.desktop
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "One-click app installer for Samsung TVs, projectors and smart monitors";
    longDescription = ''
      Apps2Samsung is a cross-platform installation utility that enables users to
      side-load any app onto Samsung devices running Tizen OS, including smart TVs,
      projectors, and monitors. It handles device detection, certificate management,
      and installation automatically, with support for Jellyfin, Moonlight, and
      community packages without requiring manual certificate handling.
    '';
    homepage = "https://github.com/Apps2Samsung/Apps2Samsung";
    downloadPage = "https://github.com/Apps2Samsung/Apps2Samsung/releases";
    changelog = "https://github.com/Apps2Samsung/Apps2Samsung/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      confused-engineer
      patrickst1991
    ];
    platforms = lib.platforms.linux;
    mainProgram = pname;
  };
}
