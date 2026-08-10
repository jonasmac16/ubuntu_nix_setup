{ config, pkgs, ... }:

{
  # OneDrive client (abraunegg/onedrive). Syncs ~/OneDrive against your
  # Microsoft account; config lives in ~/.config/onedrive/config.
  #
  # First-time setup is interactive: run `onedrive`, open the printed URL,
  # authorize, then the monitor service below starts working. Until then it
  # exits and restarts every 10s (harmless).
  home.packages = with pkgs; [
    onedrive
  ];

  xdg.configFile."onedrive/config".text = ''
    sync_dir = "~/OneDrive"
    skip_file = "~*|.~*|*.tmp|*.swp"
    monitor_interval = "300"
  '';

  systemd.user.services.onedrive = {
    Unit = {
      Description = "OneDrive client";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      ExecStart = "${pkgs.onedrive}/bin/onedrive --monitor";
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
