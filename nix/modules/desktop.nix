{ config, pkgs, lib, ... }:

{
  # Wayland desktop essentials: screenshots, clipboard, audio, media keys,
  # brightness, Bluetooth GUI, keyring, desktop portals, auto-mount.
  #
  # System-side daemons these depend on (udisks2, polkitd, bluez) are
  # installed by the Ansible playbook; everything below runs in the user
  # session and is declared here.
  home.packages = with pkgs; [
    grim
    slurp
    swappy
    cliphist
    wl-clipboard
    pavucontrol
    playerctl
    brightnessctl
    blueman
    seahorse
    polkit_gnome
  ];

  # Auto-mount removable drives in the user session (talks to the system
  # udisks2 daemon).
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "auto";
  };

  # User keyring for browser/app credentials, run as a user service.
  services.gnome-keyring.enable = true;

  # Desktop portals: file dialogs for sandboxed/Electron apps and Wayland
  # screen sharing (required by obs-studio on Wayland).
  xdg.portal = {
    enable = true;
    config.common.default = [ "gtk" ];
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
  };
}