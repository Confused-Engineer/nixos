{ lib
, stdenv
, fetchFromGitHub
, dotnet-sdk_8
, patchelf
, openssl
, icu
, zlib
, libgcc
, krb5
, fontconfig
, freetype
, libGL
, xorg
, runCommand
}:

let
  krb5WithUnversionedLib = runCommand "krb5-unversioned-so" {} ''
    mkdir -p $out/lib
    ln -s ${krb5}/lib/libgssapi_krb5.so.2 $out/lib/libgssapi_krb5.so
  '';

  runtimeLibs = [
    # ── core .NET runtime ────────────────────────────────────────────────────
    stdenv.cc.cc.lib        # libstdc++.so.6, libgcc_s.so.1
    openssl
    icu
    zlib
    libgcc.lib
    krb5
    krb5WithUnversionedLib  # provides unversioned libgssapi_krb5.so

    # ── Skia / font rendering ────────────────────────────────────────────────
    fontconfig
    freetype
    libGL

    # ── X11 / Avalonia backend ───────────────────────────────────────────────
    xorg.libX11
    xorg.libICE
    xorg.libSM
    xorg.libXext
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXinerama
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXfixes
    xorg.libXtst
  ];

  libPath = lib.makeLibraryPath runtimeLibs;
  dynamicLinker = stdenv.cc.bintools.dynamicLinker;

in
stdenv.mkDerivation rec {
  pname   = "Jellyfin2Samsung";
  version = "2.2.0.4"; # bump alongside rev below

  src = fetchFromGitHub {
    owner = "Jellyfin2Samsung";
    repo  = "Samsung-Jellyfin-Installer";
    rev   = "v${version}";
    # On first build Nix will error and print the correct hash — paste it here.
    hash  = "sha256-ZG0zFvgHTz2TnY97PhSHYN6uvOWWcHyiFkv1zNgG/Ak=";
  };

  nativeBuildInputs = [ dotnet-sdk_8 patchelf ];
  buildInputs = runtimeLibs;

  preBuild = ''
    export HOME=$(mktemp -d)
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_NOLOGO=1
  '';

  buildPhase = ''
    runHook preBuild

    dotnet publish Jellyfin2Samsung-CrossOS/Jellyfin2Samsung.csproj \
      -c Release \
      -r linux-x64 \
      --self-contained true \
      -p:PublishSingleFile=false \
      -p:PublishTrimmed=false \
      -p:ContinuousIntegrationBuild=true \
      --output ./out

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/jellyfin2samsung $out/bin

    # Copy binary + all bundled native .so files
    cp -r ./out/. $out/lib/jellyfin2samsung/

    # Patch the main executable
    patchelf \
      --set-interpreter "${dynamicLinker}" \
      --set-rpath "${libPath}:$out/lib/jellyfin2samsung" \
      $out/lib/jellyfin2samsung/Jellyfin2Samsung

    # Patch every NuGet-bundled native .so (libSkiaSharp, libHarfBuzzSharp, etc.)
    find $out/lib/jellyfin2samsung -maxdepth 1 -name "*.so" | while read so; do
      patchelf \
        --set-interpreter "${dynamicLinker}" \
        --set-rpath "${libPath}:$out/lib/jellyfin2samsung" \
        "$so" 2>/dev/null || true
    done

    # Thin wrapper so the binary is on PATH with the right LD_LIBRARY_PATH
    cat > $out/bin/Jellyfin2Samsung <<EOF
    #!/bin/sh
    export LD_LIBRARY_PATH="${libPath}:$out/lib/jellyfin2samsung\''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    exec $out/lib/jellyfin2samsung/Jellyfin2Samsung "\$@"
    EOF
    chmod +x $out/bin/Jellyfin2Samsung

    runHook postInstall
  '';

  meta = {
    description = "One-click installer for Jellyfin on Samsung Tizen Smart TVs";
    homepage    = "https://github.com/Jellyfin2Samsung/Samsung-Jellyfin-Installer";
    license     = lib.licenses.mit;
    platforms   = [ "x86_64-linux" ];
    mainProgram = "Jellyfin2Samsung";
  };
}
