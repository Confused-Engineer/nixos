{
  lib,
  buildDotnetModule,
  buildFHSEnv,
  buildEnv,
  writeShellScript,
  dotnetCorePackages,
  fetchFromGitHub,
  fetchurl,
  stdenvNoCC,
  cacert,
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

  # Merged view of all NuGet packages bundled with the SDK.  Used in the
  # FOD below to exclude them from the output so they don't collide with
  # dotnet-sdk.packages in buildDotnetModule's buildInputs.
  sdkPackages = buildEnv {
    name = "${pname}-sdk-packages";
    paths = dotnetCorePackages.sdk_8_0.packages;
  };

  # Fixed-output derivation: fetches the NuGet packages that are NOT
  # bundled with the SDK.  To update the hash after a dep bump, set
  # outputHash = lib.fakeHash; build once to get the real hash, then
  # substitute it back.
  nugetDeps = stdenvNoCC.mkDerivation {
    name = "${pname}-nuget-deps";
    nativeBuildInputs = [
      dotnetCorePackages.sdk_8_0
      cacert
    ];
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-n1iSjHLYpjuSTCBLCVDxgCAYvxXy0vxicJyHSZc0FlM=";
    buildCommand = ''
      export HOME=$TMPDIR
      export DOTNET_NOLOGO=1
      export DOTNET_CLI_TELEMETRY_OPTOUT=1

      # dotnet restore needs a writable project directory for obj/
      cp -r ${src} $TMPDIR/src
      chmod -R +w $TMPDIR/src

      # Restore all NuGet packages to a temp cache
      dotnet restore \
        --packages $TMPDIR/nuget-packages \
        $TMPDIR/src/Jellyfin2Samsung-CrossOS/Apps2Samsung.csproj

      # Copy only non-SDK packages to the output.
      # dotnet-sdk.packages are already in buildInputs of the main
      # buildDotnetModule derivation; duplicating them here would cause
      # symlink collisions in the SDK setup hook's _linkPackages function.
      mkdir -p "$out/share/nuget/packages"
      while IFS= read -r -d "" pkg_dir; do
        pkgid=$(basename "$(dirname "$pkg_dir")")
        ver=$(basename "$pkg_dir")
        [ -d "${sdkPackages}/share/nuget/packages/$pkgid/$ver" ] && continue
        mkdir -p "$out/share/nuget/packages/$pkgid"
        cp -r "$pkg_dir" "$out/share/nuget/packages/$pkgid/"
      done < <(find "$TMPDIR/nuget-packages" -mindepth 2 -maxdepth 2 -type d -print0)

      # Build local NuGet feed (share/nuget/source) from our packages
      while IFS= read -r -d "" nupkg; do
        ver=$(basename "$(dirname "$nupkg")")
        pkgid=$(basename "$(dirname "$(dirname "$nupkg")")")
        dstdir="$out/share/nuget/source/$pkgid/$ver"
        mkdir -p "$dstdir"
        cp "$nupkg" "$dstdir/"
      done < <(find "$out/share/nuget/packages" -name "*.nupkg" -print0)
    '';
  };

  apps2samsung-unwrapped = buildDotnetModule {
    pname = "${pname}-unwrapped";
    inherit version src nugetDeps;

    projectFile = "Jellyfin2Samsung-CrossOS/Apps2Samsung.csproj";

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

  targetPkgs =
    pkgs: with pkgs; [
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
