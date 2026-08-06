{ config, pkgs, lib, ... }:

{
  programs.firefox = {
    enable = true;

    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;

      # Add-ons are declared from NUR (added to setup.sh). All listed addons
      # are automatically enabled on first launch via the setting below.
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        proton-pass
        bitwarden
        darkreader
        consent-o-matic
        privacy-badger
        tridactyl
        sidebery
        zotero-connector
      ];

      settings = {
        # Auto-enable all the installed extensions ("extensions.autoDisableScopes" = 0;).
        "extensions.autoDisableScopes" = 0;
        # Enable legacy styling so userChrome.css / userContent.css are applied.
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        # Privacy / UX tweaks.
        "privacy.trackingprotection.enabled" = true;
        "browser.startup.page" = 3;
        "browser.uidensity" = 1;
      };

      # Custom browser chrome (toolbar/tab styling).
      userChrome = ''
        /* Hide the vertical tab bar title if Sidebery is used */
        #sidebar-box[sidebarcommand*="sidebery"] { min-width: 250px !important; }
        /* Compact tab bar */
        .tabbrowser-tab { min-height: 32px !important; }
      '';

      # Custom site content styling (used e.g. for global dark-reader overrides).
      userContent = ''
        @-moz-document url-prefix(about:) {
          :root { background-color: #1e1e1e !important; color: #d4d4d4 !important; }
        }
      '';
    };
  };

  programs.chromium = {
    enable = true;
    extensions = [
      { id = "kncchdigobghenbbaddojjnbabogdndd"; } # Proton Pass
      { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
      { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # Vimium
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
    ];

    # Declarative progressive web apps (PWAs) for work / productivity sites.
    extraOpts.WebAppInstallForceList = [
      {
        custom_name = "MS Teams";
        url = "https://teams.microsoft.com/";
        default_launch_container = "window";
        create_desktop_shortcut = true;
      }
      {
        custom_name = "Outlook 365";
        url = "https://outlook.office.com/";
        default_launch_container = "window";
        create_desktop_shortcut = true;
      }
      {
        custom_name = "ChatGPT";
        url = "https://chatgpt.com/";
        default_launch_container = "window";
        create_desktop_shortcut = true;
      }
    ];
  };
}