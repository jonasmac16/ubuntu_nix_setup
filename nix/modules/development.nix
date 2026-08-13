{ config, pkgs, lib, ... }:

{
  # ------------------------------------------------ VSCode
  programs.vscode = {
    enable = true;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        catppuccin.catppuccin-vsc
        catppuccin.catppuccin-vsc-icons
        ms-python.python
        ms-toolsai.jupyter
        julialang.language-julia
        mechatroner.rainbow-csv
        ms-vscode-remote.remote-ssh
        ms-azuretools.vscode-docker
        jnoortheen.nix-ide
        esbenp.prettier-vscode
        usernamehw.errorlens
        eamodio.gitlens
        pkief.material-icon-theme
      ];

      # Apptainer has no dedicated VSCode extension in nixpkgs; containers are
      # handled by the Docker extension + the apptainer CLI below.

      userSettings = {
        # Editor defaults
        "editor.formatOnSave" = true;
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.minimap.enabled" = true;
        "files.autoSave" = "afterDelay";
        "workbench.colorTheme" = "Catppuccin Mocha";
        "workbench.iconTheme" = "catppuccin-icons";

        # Prettier
        "prettier.singleQuote" = true;
        "prettier.trailingComma" = "all";

        # ErrorLens
        "errorLens.enabled" = true;
        "errorLens.addInProblemOverview" = true;

        # GitLens
        "gitlens.defaultDateFormat" = "relative";

        # Python
        "python.analysis.typeCheckingMode" = "basic";

        # Julia
        "julia.enableTelemetry" = false;

        # Nix
        "nix.enableLanguageServer" = true;
      };
    };
  };

  # ------------------------------------------------ Terminal & tools
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        size = 11.0;
        normal = {
          family = "JetBrains Mono";
          style = "Regular";
        };
      };
      window = {
        opacity = 0.95;
        decorations = "full";
      };
      colors = {
        primary = {
          background = "#1e1e2e";
          foreground = "#cdd6f4";
        };
        cursor = { text = "#1e1e2e"; cursor = "#f5c2e7"; };
        normal = { black = "#45475a"; red = "#f38ba8"; green = "#a6e3a1"; yellow = "#f9e2af"; blue = "#89b4fa"; magenta = "#f5c2e7"; cyan = "#94e2d5"; white = "#bac2de"; };
        bright = { black = "#585b70"; red = "#f38ba8"; green = "#a6e3a1"; yellow = "#f9e2af"; blue = "#89b4fa"; magenta = "#f5c2e7"; cyan = "#94e2d5"; white = "#a6adc8"; };
      };
      key_bindings = [
        {
          key = "F11";
          action = "ToggleFullscreen";
        }
      ];
    };
  };

  # ------------------------------------------------ Coding agents
  home.packages = with pkgs; [
    # AI coding agents
    opencode
    pi-coding-agent
    nodejs_22

    # Containers / VMs
    quickemu
    distrobox
    podman
    apptainer

    # Network CLI tools
    lftp
    openssh # provides sftp/scp/ssh client (also pulled in by programs.ssh)

    # Terminal tools
    btop
    fd
    jq
    yazi
    lazygit
  ];

  # ------------------------------------------------ Neovim
  programs.neovim = {
    enable = true;
    viAlias = true;
    # Minimal, dependency-free init.lua. Extend here or in $XDG_CONFIG_HOME/nvim.
    initLua = ''
      local opt = vim.opt
      opt.number = true
      opt.relativenumber = true
      opt.expandtab = true
      opt.shiftwidth = 2
      opt.tabstop = 2
      opt.ignorecase = true
      opt.smartcase = true
      opt.termguicolors = true
      vim.cmd.colorscheme("catppuccin-mocha")
      opt.clipboard = "unnamedplus"

      vim.g.mapleader = " "
      vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save" })
      vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "Quit" })
    '';
    plugins = [ pkgs.vimPlugins.catppuccin-nvim ];
  };

  # ------------------------------------------------ Shell-integrated tools
  # Each *programs* option installs the package AND wires its shell integration
  # into bash (managed by modules/shell.nix).
  programs.zoxide.enable = true; # smart `cd` with an fzf-powered picker
  programs.bat.enable = true;    # cat clone with syntax highlighting
  programs.eza.enable = true;    # modern ls replacement
  programs.tmux = {
    enable = true;
    plugins = [ pkgs.tmuxPlugins.catppuccin ];
    extraConfig = ''
      set -g @catppuccin_flavour 'mocha'
    '';
  };

  home.file.".config/bat/themes/Catppuccin Mocha.tmTheme".source = pkgs.fetchurl {
    name = "catppuccin-mocha.tmTheme";
    url = "https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme";
    hash = "sha256-OVVm8IzrMBuTa5HAd2kO+U9662UbEhVT8gHJnCvUqnc=";
  };

  home.file.".config/bat/config".text = ''
    --theme="Catppuccin Mocha"
  '';

}
