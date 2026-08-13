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
        :root {
          --ctp-base: #1e1e2e;
          --ctp-mantle: #181825;
          --ctp-crust: #11111b;
          --ctp-text: #cdd6f4;
          --ctp-blue: #89b4fa;
        }
        #navigator-toolbox, #TabsToolbar { background: var(--ctp-mantle) !important; color: var(--ctp-text) !important; }
        .tabbrowser-tab[selected] .tab-background { background: var(--ctp-blue) !important; }
        .tabbrowser-tab[selected] .tab-label { color: var(--ctp-crust) !important; }
        /* Hide the vertical tab bar title if Sidebery is used */
        #sidebar-box[sidebarcommand*="sidebery"] { min-width: 250px !important; }
        /* Compact tab bar */
        .tabbrowser-tab { min-height: 32px !important; }
      '';

      # Custom site content styling (used e.g. for global dark-reader overrides).
      userContent = ''
        @-moz-document url-prefix(about:) {
           :root { background-color: #1e1e2e !important; color: #cdd6f4 !important; }
           * { scrollbar-color: #585b70 #1e1e2e !important; }
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
      { id = "lmeddoobegbaiopohmpmmobpnpjifpii"; } # Open in Firefox
    ];
  };

  # Open in Firefox (native messaging host). The extension hands a URL to the
  # com.add0n.node host over Chrome's native-messaging protocol, which spawns
  # Firefox. The manifest below mirrors what the upstream native-client
  # installer would write into the user-level NativeMessagingHosts directory.
  home.file.".config/chromium/NativeMessagingHosts/com.add0n.node.json" = {
    text = builtins.toJSON {
      name = "com.add0n.node";
      description = "NodeJS Host by WebExtension.ORG for Browser Native Messaging";
      path = "${pkgs.openin-native-host}/share/openin/run.sh";
      type = "stdio";
      allowed_origins = [ "chrome-extension://lmeddoobegbaiopohmpmmobpnpjifpii/" ];
    };
  };

  # Open in Firefox managed policy (chrome.storage.managed). In reverse mode the
  # listed base URLs are EXEMPT: left-clicked links on these hosts stay in
  # Chromium while everything else is handed to Firefox. Note the extension
  # ignores `urls` when `hosts` is non-empty, so `hosts` must stay empty.
  home.file.".config/chromium/policies/managed/lmeddoobegbaiopohmpmmobpnpjifpii.json" = {
    text = builtins.toJSON {
      hosts = [ ];
      urls = [
        "https://teams.microsoft.com/"
        "https://outlook.cloud.microsoft/"
        "https://unioxfordnexus.sharepoint.com/"
        "https://chatgpt.com/"
      ];
      reverse = true;
    };
  };

  # Declarative progressive web apps (PWAs) for work / productivity sites.
  # Home Manager's chromium module no longer exposes `extraOpts`, so the
  # WebAppInstallForceList policy is written to Chromium's user-level managed
  # policy directory (read on every Linux launch).
  home.file.".config/chromium/policies/managed/pwas.json" = {
    text = builtins.toJSON {
      WebAppInstallForceList = [
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
  };
}
