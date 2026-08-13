{ config, pkgs, keyboardLayout ? "us,gb", ... }:

{
  home.packages = with pkgs; [
    foot
    wofi
    jq
    waybar
    mako
    swaybg
    nerd-fonts.jetbrains-mono
    (pkgs.writeShellScriptBin "wofi-launcher" ''
      set -eu

      entries=$(mktemp)
      trap 'rm -f "$entries"' EXIT

      find "$HOME/.local/share/applications" /usr/share/applications \
        -type f -name '*.desktop' -print 2>/dev/null | sort -u | while read -r desktop; do
        [ "$(grep -E '^NoDisplay=true' "$desktop" || true)" ] && continue
        name=$(grep -m1 '^Name=' "$desktop" | cut -d= -f2- || true)
        [ -n "$name" ] || continue
        printf 'app\t%s\t%s\n' "$name" "$(basename "$desktop" .desktop)" >> "$entries"
      done

      swaymsg -t get_tree | jq -r '
        .. | objects
        | select(.type? == "con" and .name? != null and (.app_id? != null or .window_properties? != null))
        | ["window", .name, (.id | tostring)] | @tsv
      ' >> "$entries"

      choice=$(cut -f1,2 "$entries" | sed 's/^app\t/[App] /; s/^window\t/[Window] /' | \
        wofi --dmenu --prompt Launcher --insensitive) || exit 0
      [ -n "$choice" ] || exit 0

      kind=$(printf '%s\n' "$choice" | cut -d' ' -f1)
      name=$(printf '%s\n' "$choice" | cut -d' ' -f2-)
      if [ "$kind" = "[App]" ]; then
        id=$(awk -F '\t' -v name="$name" '$1 == "app" && $2 == name { print $3; exit }' "$entries")
        gtk-launch "$id"
      else
        id=$(awk -F '\t' -v name="$name" '$1 == "window" && $2 == name { print $3; exit }' "$entries")
        swaymsg "[con_id=$id] focus"
      fi
    '')
  ];

  home.file.".local/share/backgrounds/catppuccin-mocha.jpg".source = pkgs.fetchurl {
    url = "https://wallpapercave.com/wp/wp15570840.jpg";
    sha256 = "111p3vxpvsv7bl3sc0pa78q302x0a41620gjd4h3i4zx0mmhp557";
  };

  home.file.".config/wofi/style.css".text = ''
    window {
      margin: 0;
      border: 2px solid #89b4fa;
      border-radius: 12px;
      background-color: #1e1e2e;
    }
    #input {
      margin: 12px;
      color: #cdd6f4;
      background-color: #313244;
      border: 1px solid #45475a;
      border-radius: 8px;
      padding: 8px;
    }
    #inner-box { margin: 0 8px 8px; background-color: #1e1e2e; }
    #entry { padding: 9px 12px; color: #cdd6f4; border-radius: 8px; }
    #entry:selected { color: #1e1e2e; background-color: #89b4fa; }
  '';

  home.file.".config/foot/foot.ini".text = ''
    [main]
    font=JetBrainsMono Nerd Font:size=11
    pad=10x8

    [colors]
    alpha=0.95
    background=1e1e2e
    foreground=cdd6f4
    regular0=45475a
    regular1=f38ba8
    regular2=a6e3a1
    regular3=f9e2af
    regular4=89b4fa
    regular5=f5c2e7
    regular6=94e2d5
    regular7=bac2de
    bright0=585b70
    bright1=f38ba8
    bright2=a6e3a1
    bright3=f9e2af
    bright4=89b4fa
    bright5=f5c2e7
    bright6=94e2d5
    bright7=a6adc8
    cursor=1e1e2e f5c2e7
  '';

  services.mako = {
    enable = true;
    settings = {
      background-color = "#1e1e2e";
      text-color = "#cdd6f4";
      border-color = "#89b4fa";
      progress-color = "over #313244";
      border-radius = 8;
      border-size = 2;
      default-timeout = 5000;
      font = "JetBrains Mono 10";
    };
  };

  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod4";
      terminal = "foot";
      menu = "wofi-launcher";
      bars = [];
      input = {
        "type:keyboard" = {
          xkb_layout = keyboardLayout;
          xkb_options = "caps:escape";
        };
      };
      startup = [
        { command = "swaybg -i ~/.local/share/backgrounds/catppuccin-mocha.jpg -m fill"; }
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

        # Clipboard history picker (cliphist + Wofi).
        "Mod4+v" = "exec cliphist list | wofi --dmenu | cliphist decode | wl-copy";

        # Combined application and open-window launcher.
        "Mod4+d" = "exec wofi-launcher";

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

      colors = {
        focused = { background = "#89b4fa"; border = "#89b4fa"; childBorder = "#89b4fa"; text = "#1e1e2e"; indicator = "#f5c2e7"; };
        focusedInactive = { background = "#313244"; border = "#313244"; childBorder = "#313244"; text = "#cdd6f4"; indicator = "#f5c2e7"; };
        unfocused = { background = "#1e1e2e"; border = "#1e1e2e"; childBorder = "#1e1e2e"; text = "#6c7086"; indicator = "#f5c2e7"; };
        urgent = { background = "#f38ba8"; border = "#f38ba8"; childBorder = "#f38ba8"; text = "#1e1e2e"; indicator = "#f5c2e7"; };
      };
    };
  };

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        modules-left = [ "sway/workspaces" "sway/window" ];
        modules-center = [ "sway/workspaces" ];
        modules-right = [ "custom/notifications" "network" "pulseaudio" "tray" "clock" ];
        "sway/workspaces" = { disable-scroll = true; all-outputs = true; format = "{name}"; };
        "sway/window" = { max-length = 80; tooltip = false; };
        "custom/notifications" = { format = "󰂚  {}"; exec = "sh -c 'makoctl list 2>/dev/null | wc -l'"; interval = 2; on-click = "makoctl dismiss -a"; tooltip = false; };
        network = { format-wifi = "󰤨 {essid}"; format-ethernet = "󰈀 {ifname}"; format-disconnected = "󰤭 offline"; tooltip-format = "{ifname}: {ipaddr}"; };
        pulseaudio = { format = "{icon} {volume}%"; format-muted = "󰝟 muted"; format-icons = { default = [ "󰕿" "󰖀" "󰕾" ]; }; on-click = "pavucontrol"; };
        tray = { spacing = 8; icon-size = 16; tooltip = true; };
        clock = { format = "󰥔 {:%a %d %b  %H:%M}"; tooltip = false; };
      };
    };
    style = ''
      * { font-family: "JetBrainsMono Nerd Font", "JetBrains Mono"; font-size: 12px; }
      window#waybar { background: #1e1e2e; color: #cdd6f4; }
      #workspaces button { padding: 0 8px; color: #6c7086; }
      #workspaces button.focused { color: #1e1e2e; background: #89b4fa; }
      #window { color: #bac2de; padding-left: 12px; }
      #custom-notifications, #network, #pulseaudio, #tray, #clock { padding: 0 10px; }
      #custom-notifications { color: #f5c2e7; }
      #network { color: #a6e3a1; }
      #pulseaudio { color: #f9e2af; }
      #clock { color: #89dceb; }
    '';
  };
}
