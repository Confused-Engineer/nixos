{ lib, config, pkgs, ... }:

  let
    cfg = config.custom.apps.browsers.firefox;
  in
{


  options.custom.apps.browsers = {
  
    firefox = {
      enable = lib.mkEnableOption "Enable Firefox";

      DisableFirefoxAccounts = lib.mkEnableOption "Enable Firefox Accouts";

      privacy = lib.mkOption {
        type = lib.types.enum [ "strict" "moderate" "permissive" ];
        default = "permissive";
        description = "Controls privacy settings of Firefox.";
        # lib.mkIf ( cfg.privacy == "strict" || cfg.privacy == "moderate" )
      };

      homepage = lib.mkOption {
        type = lib.types.str;
        default = "https://www.google.com";
        description = "Firefox Home Page.";
        # lib.mkIf ( cfg.privacy == "strict" || cfg.privacy == "moderate" )
      };

    };

  };

  config = lib.mkIf cfg.enable {
    programs = {
      firefox = {
        enable = true;
        languagePacks = [ "en-US" ];

        /* ---- POLICIES ---- */
        # Check about:policies#documentation for options.
        policies = {
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          EnableTrackingProtection = {
            Value= true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
          DisablePocket = true;
          DisableFirefoxAccounts = cfg.DisableFirefoxAccounts;
          DisableAccounts = cfg.DisableFirefoxAccounts;
          DisableFirefoxScreenshots = true;
          OverrideFirstRunPage = "";
          OverridePostUpdatePage = "";
          DontCheckDefaultBrowser = true;
          DisplayBookmarksToolbar = "newtab"; # alternatives: "always", "newtab", "never"
          DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
          SearchBar = "unified"; # alternative: "separate"

          /* ---- EXTENSIONS ---- */
          # Check about:support for extension/add-on ID strings.
          # Valid strings for installation_mode are "allowed", "blocked",
          # "force_installed" and "normal_installed".
          ExtensionSettings = {
            "*".installation_mode = "blocked"; # blocks all addons except the ones specified below
            # uBlock Origin:
            "uBlock0@raymondhill.net" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              installation_mode = "force_installed";
            };
            # Privacy Badger:
            "@testpilot-containers" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi";
              installation_mode = "force_installed";
            };
            # Bitwarden:
            "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
              installation_mode = "force_installed";
            };
          };
    
          /* ---- PREFERENCES ---- */
          # Check about:config for options.
          Preferences = { 
            "browser.contentblocking.category" = { Value = "strict"; Status = "locked"; };
            "extensions.pocket.enabled" = ( cfg.privacy == "permissive" );
            "extensions.screenshots.disabled" = ( cfg.privacy == "strict" );
            "browser.topsites.contile.enabled" = true;
            "browser.formfill.enable" = ( cfg.privacy != "strict" );
            "browser.search.suggest.enabled" = ( cfg.privacy != "strict" );
            "browser.search.suggest.enabled.private" = ( cfg.privacy != "strict" );
            "browser.urlbar.suggest.searches" = ( cfg.privacy != "strict" );
            "browser.urlbar.showSearchSuggestionsFirst" = ( cfg.privacy != "strict" );
            "browser.newtabpage.activity-stream.feeds.section.topstories" = (cfg.privacy == "permissive");
            "browser.newtabpage.activity-stream.feeds.snippets" = (cfg.privacy == "permissive");
            "browser.newtabpage.activity-stream.section.highlights.includePocket" = ( cfg.privacy != "strict" );
            "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = ( cfg.privacy != "strict" );
            "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = ( cfg.privacy != "strict" );
            "browser.newtabpage.activity-stream.section.highlights.includeVisited" = ( cfg.privacy != "strict" );
            "browser.newtabpage.activity-stream.showSponsored" = (cfg.privacy == "permissive");
            "browser.newtabpage.activity-stream.system.showSponsored" = (cfg.privacy == "permissive");
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = (cfg.privacy == "permissive");
            "browser.startup.homepage" = cfg.homepage;
            "browser.startup.homepage.abouthome_cache.enabled" = true;
          };
        };
      };
    };

  };

}