{ config, pkgs, lib, ... }:

{ 
  imports = [
    ./hardware-configuration.nix
    ./modules/users/nuser.nix
    ./modules/shells/zsh.nix
    ./modules/tools/fzf.nix
    ./modules/desktop/sway.nix
    ./modules/desktop/rofi.nix
    ./modules/services/ollama.nix
    ./modules/services/pipewire.nix
  ];

  # Bootloader settings
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      persistent = true;
      options = "--delete-older-than 30d";
    };
  };

  # Declarative Brave Debloat & Hardening Policy (Modern)
  environment.etc."brave/policies/managed/debloat.json".text = builtins.toJSON {
    # 1. Disable Crypto / Web3
    BraveRewardsDisabled = true;
    BraveWalletDisabled = true;

    # 2. Disable AI & Built-in Services
    BraveAIChatEnabled = false;       # Disables Brave Leo AI
    BraveVPNDisabled = true;          # Disables Brave VPN integration & promotions
    TorDisabled = true;               # Disables Tor private windows
    BraveNewsDisabled = true;         # Disables Brave News feed
    BraveTalkDisabled = true;         # Disables Brave Talk WebRTC service
    BraveSpeedreaderEnabled = false;

    # 3. Strip Telemetry & Background Pings
    BraveP3AEnabled = false;          # Privacy-Preserving Product Analytics
    BraveStatsPingEnabled = false;    # Daily active user ping
    BraveWebDiscoveryEnabled = false; # Search query collection
    MetricsReportingEnabled = false;  # Chromium crash/metrics reports
    FeedbackSurveysEnabled = false;

    # 4. Browser Cleanliness & Modern Autofill Blocking
    PasswordManagerEnabled = true;   # Prevents saving passwords (for KeePassXC)
    BackgroundModeEnabled = false;    # Prevents lingering in RAM when closed
    AutofillSettings = [              # Modern replacement for legacy autofill flags
      {
        url_pattern = "*";
        blocked_types = [
          "contact_info"
          "payments"
          "identity_docs"
          "travel"
        ];
      }
    ];
  };

  # Enable XDG Desktop Portals for Wayland / Sway (required for file dialogs, keyring & screensharing)
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
    config.common.default = [ "gtk" ];
  };

  # Force native Wayland & Intel iHD VA-API driver
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    LIBVA_DRIVER_NAME = "iHD";
  };

  modules = {
    user.enable = true;
    user.name = "nuser";
    
    zsh.enable = true;
    zsh.powerlevel10k = true;

    fzf.enable = true;
    fzf.enablePreviews = true;
   
    sway.enable = true;
    # sway.autologin = true;
    
    pipewire.enable = true;
    pipewire.pulse = true;
  };

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  environment.variables.GTK_THEME = "Adwaita:dark";

  # Virtualization
  virtualisation.docker.enable = true;

  # Security & Bluetooth
  security.rtkit.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  # Hardware Graphics Acceleration (Intel)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver   # Hardware VA-API decoding (Broadwell / Gen 8+)
      libva-utils          # Provides vainfo for diagnostics
      vpl-gpu-rt           # OneVPL runtime for Intel Quick Sync
    ];
  };

  nixpkgs.config.allowUnfree = true;

  # Shell Shebang & Dynamic Linking Fixes for Mason / LSPs
  services.envfs.enable = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      zlib
      zstd
      stdenv.cc.cc
      curl
      openssl
    ];
  };

  # Cron Jobs (using absolute paths since cron does not expand $HOME)
  services.cron = {
    enable = true;
    systemCronJobs = [
      "*/5 * * * *  nuser  /home/nuser/vault/sync-passwords.sh"
      "0 17 * * *   nuser  /home/nuser/scripts/backup.sh"
    ];
  };

  # Blueman & Networking
  services.blueman.enable = true;
  services.resolved.enable = true;

  # Power Management & Battery Monitoring
  services.upower.enable = true;

  # Audio (PipeWire primary, PulseAudio explicitly disabled)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # Prevents the mod.x11-bell SIGSEGV crash when Bluetooth connects or Xwayland resets
    extraConfig.pipewire = {
      "99-disable-bell" = {
        "context.properties" = {
          "module.x11.bell" = false;
        };
      };
    };
  };
  services.pulseaudio.enable = false;

  # Default Shell & User Groups
  users.defaultUserShell = pkgs.zsh;
  users.users.nuser = {
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "audio" "bluetooth" "docker" ];
  };

  programs.dconf = {
    enable = true;
    profiles.user.databases = [{
      settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    }];
  };

  # Prevent Twingate from auto-starting on boot or rebuilds
  systemd.services.twingate.wantedBy = lib.mkForce [ ];

  # Secure /boot Permissions
  fileSystems."/boot".options = lib.mkForce [ "fmask=0077" "dmask=0077" ];

  networking.hostName = "nixos-nuser";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Riga";

  # Security & Key Agents
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.gnome.gcr-ssh-agent.enable = false;

  programs.ssh.startAgent = true;

  # GPG Agent with Pinentry
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
  };

  # System Packages
  environment.systemPackages = with pkgs; [
    brave
    tree
    killall
    bash 
    vim
    neovim
    git
    firefox
    keepassxc
    rofi
    thunar
    cliphist
    swappy
    meld
    glib
    pwvucontrol
    appimage-run
    btop
    blueman
    networkmanagerapplet
    joplin-desktop
    tree-sitter
    gcc
    gnumake
    libnotify
    wlsunset
    unzip
    ripgrep
    fd
    gnupg
    terraform-docs
    argo-workflows
  ];

  fonts.packages = with pkgs; [
    font-awesome_4
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
    nerd-fonts.hack
    font-awesome
  ];

  system.stateVersion = "26.05";
}
