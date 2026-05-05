{ lib, config, pkgs, ... }:
let
  cfg = config.custom.apps.browsers.firefox;

  isStrict     = cfg.privacy == "strict";
  isPermissive = cfg.privacy == "permissive";
  notStrict    = cfg.privacy != "strict";
in {
  options.custom.apps.browsers.firefox = {
    enable = lib.mkEnableOption "Firefox with hardened policies";

    # Renamed from `DisableFirefoxAccounts` to follow normal nix casing.
    # The old name's description was also inverted ("Enable Firefox Accouts"
    # for an option that disables them).
    disableAccounts = lib.mkEnableOption "disabling Firefox Sync / Accounts";

    privacy = lib.mkOption {
      type        = lib.types.enum [ "strict" "moderate" "permissive" ];
      default     = "permissive";
      description = "Privacy preset applied to Firefox preferences.";
    };

    homepage = lib.mkOption {
      type        = lib.types.str;
      default     = "https://www.google.com";
      description = "Firefox home page.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable        = true;
      languagePacks = [ "en-US" ];

      # See about:policies#documentation for valid keys.
      policies = {
        DisableTelemetry         = true;
        DisableFirefoxStudies    = true;
        EnableTrackingProtection = {
          Value          = true;
          Locked         = true;
          Cryptomining   = true;
          Fingerprinting = true;
        };
        DisablePocket             = true;
        DisableFirefoxAccounts    = cfg.disableAccounts;
        DisableAccounts           = cfg.disableAccounts;
        DisableFirefoxScreenshots = true;
        OverrideFirstRunPage      = "";
        OverridePostUpdatePage    = "";
        DontCheckDefaultBrowser   = true;
        DisplayBookmarksToolbar   = "newtab";
        DisplayMenuBar            = "default-off";
        SearchBar                 = "unified";

        ExtensionSettings = {
          # Block all addons except those listed below.
          "*".installation_mode = "blocked";
          "uBlock0@raymondhill.net" = {
            install_url       = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
          };
          "@testpilot-containers" = {
            install_url       = "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi";
            installation_mode = "force_installed";
          };
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
            install_url       = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
            installation_mode = "force_installed";
          };
        };

        Preferences = {
          "browser.contentblocking.category"                                          = { Value = "strict"; Status = "locked"; };
          "extensions.pocket.enabled"                                                 = isPermissive;
          "extensions.screenshots.disabled"                                           = isStrict;
          "browser.topsites.contile.enabled"                                          = true;
          "browser.formfill.enable"                                                   = notStrict;
          "browser.search.suggest.enabled"                                            = notStrict;
          "browser.search.suggest.enabled.private"                                    = notStrict;
          "browser.urlbar.suggest.searches"                                           = notStrict;
          "browser.urlbar.showSearchSuggestionsFirst"                                 = notStrict;
          "browser.newtabpage.activity-stream.feeds.section.topstories"               = isPermissive;
          "browser.newtabpage.activity-stream.feeds.snippets"                         = isPermissive;
          "browser.newtabpage.activity-stream.section.highlights.includePocket"       = notStrict;
          "browser.newtabpage.activity-stream.section.highlights.includeBookmarks"    = notStrict;
          "browser.newtabpage.activity-stream.section.highlights.includeDownloads"    = notStrict;
          "browser.newtabpage.activity-stream.section.highlights.includeVisited"      = notStrict;
          "browser.newtabpage.activity-stream.showSponsored"                          = isPermissive;
          "browser.newtabpage.activity-stream.system.showSponsored"                   = isPermissive;
          "browser.newtabpage.activity-stream.showSponsoredTopSites"                  = isPermissive;
          "browser.startup.homepage"                                                  = cfg.homepage;
          "browser.startup.homepage.abouthome_cache.enabled"                          = true;
        };
      };
    };
  };
}
