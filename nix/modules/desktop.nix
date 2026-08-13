{ config, pkgs, lib, ... }:

{
  # Wayland desktop essentials: screenshots, clipboard, audio, media keys,
  # brightness, Bluetooth GUI, keyring, desktop portals, auto-mount.
  #
  # System-side daemons these depend on (udisks2, polkitd, bluez) are
  # installed by the Ansible playbook; everything below runs in the user
  # session and is declared here.
  home.packages = with pkgs; [
    catppuccin-papirus-folders
    catppuccin-qt5ct
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
    config.sway.default = [ "wlr" "gtk" ];
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
  };

  gtk = {
    enable = true;
    theme.name = "Adwaita-dark";
    iconTheme = {
      package = pkgs.catppuccin-papirus-folders;
      name = "Papirus-Dark";
    };
    font = { name = "JetBrains Mono 10"; package = pkgs.nerd-fonts.jetbrains-mono; };
  };

  qt = {
    enable = true;
    platformTheme.name = lib.mkForce "qt6ct";
    style.name = "Fusion";
  };

  home.sessionVariables = {
    GTK_THEME = "Adwaita-dark";
    QT_QPA_PLATFORMTHEME = "qt6ct";
  };

  home.file.".config/qt6ct/colors".source = "${pkgs.catppuccin-qt5ct}/share/qt6ct/colors";
  home.file.".config/qt6ct/qt6ct.conf".text = ''
    [Appearance]
    style=Fusion
    color_scheme=catppuccin-mocha-mauve
  '';

  home.file.".config/gtk-3.0/gtk.css".text = ''
    @define-color theme_bg_color #1e1e2e;
    @define-color theme_fg_color #cdd6f4;
    @define-color theme_selected_bg_color #89b4fa;
    @define-color theme_selected_fg_color #1e1e2e;
    @define-color borders #45475a;
    * { color: @theme_fg_color; }
    window, dialog, .background { background-color: @theme_bg_color; }
    entry, textview, treeview, notebook { background-color: #181825; color: @theme_fg_color; }
    entry:focus, button:checked, row:selected { background-color: @theme_selected_bg_color; color: @theme_selected_fg_color; }
  '';

  home.file.".config/gtk-4.0/gtk.css".text = ''
    @define-color theme_bg_color #1e1e2e;
    @define-color theme_fg_color #cdd6f4;
    @define-color theme_selected_bg_color #89b4fa;
    @define-color theme_selected_fg_color #1e1e2e;
    window, dialog, .background { background-color: @theme_bg_color; color: @theme_fg_color; }
    entry, textview, list, row { background-color: #181825; color: @theme_fg_color; }
    entry:focus, row:selected { background-color: @theme_selected_bg_color; color: @theme_selected_fg_color; }
  '';
}
