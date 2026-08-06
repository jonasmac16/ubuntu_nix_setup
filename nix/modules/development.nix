{ config, pkgs, lib, ... }:

{
  # ------------------------------------------------ VSCode
  programs.vscode = {
    enable = true;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
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
        "workbench.iconTheme" = "material-icon-theme";

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
      opt.clipboard = "unnamedplus"

      vim.g.mapleader = " "
      vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save" })
      vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "Quit" })
    '';
  };

  # ------------------------------------------------ Shell-integrated tools
  # Each *programs* option installs the package AND wires its shell integration
  # into bash (managed by modules/shell.nix).
  programs.zoxide.enable = true; # smart `cd` with an fzf-powered picker
  programs.bat.enable = true;    # cat clone with syntax highlighting
  programs.eza.enable = true;    # modern ls replacement
  programs.tmux.enable = true;   # terminal multiplexer

}