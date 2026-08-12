{ config, pkgs, keyboardLayout ? "us,gb", ... }:

{
  home.packages = with pkgs; [
    foot
    wofi
    waybar
    mako
  ];

  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod4";
      terminal = "foot";
      menu = "wofi --show drun";
      bars = [];
      input = {
        "type:keyboard" = {
          xkb_layout = keyboardLayout;
          xkb_options = "caps:escape";
        };
      };
      startup = [
        { command = "waybar"; }
        { command = "mako"; }
        # polkit authentication agent: needed for privileged prompts (udisks2
        # mounts, package installs) from Wayland apps. See modules/desktop.nix.
        { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; }
      ];

      # Screenshots, clipboard history, volume and media controls.
      # Home Manager wraps the sway defaults in mkOptionDefault, so the
      # bindings below ADD to the defaults (except Super+V, which replaces the
      # default "splitv").
      keybindings = {
        # Screenshots: region (Print), full screen (Shift+Print); edited in swappy.
        "Print" = ''exec grim -g "$(slurp)" - | swappy -f -'';
        "Shift+Print" = "exec grim - | swappy -f -";

        # Clipboard history picker (cliphist + wofi).
        "Mod4+v" = "exec cliphist list | wofi --dmenu | cliphist decode | wl-copy";

        # Toggle between the configured US and GB keyboard layouts.
        "Mod4+space" = "input type:keyboard xkb_switch_layout next";

        # Volume via PipeWire (wpctl ships with wireplumber, installed
        # system-wide by the Ansible playbook).
        "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

        # Media playback controls.
        "XF86AudioPlay" = "exec playerctl play-pause";
        "XF86AudioNext" = "exec playerctl next";
        "XF86AudioPrev" = "exec playerctl previous";
      };
    };
  };

  programs.waybar.enable = true;
}
