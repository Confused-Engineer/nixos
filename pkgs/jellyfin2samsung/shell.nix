{ pkgs ? import <nixpkgs> {} }:

let
  krb5WithUnversionedLib = pkgs.runCommand "krb5-unversioned-so" {} ''
    mkdir -p $out/lib
    ln -s ${pkgs.krb5}/lib/libgssapi_krb5.so.2 $out/lib/libgssapi_krb5.so
  '';

  # FHS environment that provides /lib, /lib64, /usr/lib etc.
  # so dynamically linked binaries (TizenSdb, .NET native bits) just work.
  fhs = pkgs.buildFHSEnv {
    name = "jellyfin2samsung-fhs";

    targetPkgs = p: with p; [
      # ── build tooling ──────────────────────────────────────────────────────
      dotnet-sdk_8
      patchelf
      file

      # ── core .NET runtime ──────────────────────────────────────────────────
      stdenv.cc.cc.lib
      openssl
      icu
      zlib
      libgcc.lib
      krb5
      krb5WithUnversionedLib

      # ── Skia / font rendering ─────────────────────────────────────────────
      fontconfig
      freetype
      libGL

      # ── X11 / Avalonia backend ─────────────────────────────────────────────
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

      # ── networking / utilities ─────────────────────────────────────────────
      nmap
      iproute2
      curl
      wget
      xdg-utils
    ];

    runScript = pkgs.writeShellScript "jellyfin2samsung-entry" ''
      export DOTNET_CLI_TELEMETRY_OPTOUT=1
      export DOTNET_NOLOGO=1

      # Write the helpers to a file bash will source
      RCFILE="$(mktemp)"
      cat > "$RCFILE" << 'BASHRC'
      # Source the user's bashrc first for prompt, aliases, etc.
      [ -f ~/.bashrc ] && source ~/.bashrc

      function build-jellyfin2samsung() {
        echo "→ Building..."
        dotnet publish Jellyfin2Samsung-CrossOS/Jellyfin2Samsung.csproj \
          -c Release \
          -r linux-x64 \
          --self-contained true \
          -p:PublishSingleFile=false \
          -p:PublishTrimmed=false

        local PUBLISH_DIR="Jellyfin2Samsung-CrossOS/bin/Release/net8.0/linux-x64/publish"
        if [[ ! -f "$PUBLISH_DIR/Jellyfin2Samsung" ]]; then
          echo "✗ Build failed"
          return 1
        fi

        echo "✓ Done. Run with: $PUBLISH_DIR/Jellyfin2Samsung"
      }
      BASHRC

      echo ""
      echo "  You are inside an FHS environment — dynamically linked"
      echo "  binaries (TizenSdb, .NET native libs) work out of the box."
      echo ""
      echo "  build-jellyfin2samsung  — build the project"
      echo "  Then run: Jellyfin2Samsung-CrossOS/bin/Release/net8.0/linux-x64/publish/Jellyfin2Samsung"
      echo ""

      exec bash --rcfile "$RCFILE"
    '';
  };

in
pkgs.mkShell {
  name = "jellyfin2samsung";

  buildInputs = [
    fhs
  ];

  shellHook = ''
    echo "Run 'jellyfin2samsung-fhs' to enter the FHS build environment."
    echo "Inside it, all dynamically linked executables will work natively."
  '';
}
