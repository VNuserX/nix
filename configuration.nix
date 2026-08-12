{ config, pkgs, lib, ... }:

{ 
  imports = [
    ./hardware-configuration.nix
    ./modules/users/nuser.nix
    ./modules/shells/zsh.nix
    ./modules/tools/fzf.nix
    ./modules/desktop/sway.nix
    ./modules/services/pipewire.nix
  ];

  # Bootloader settings
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  # Automatic weekly garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
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

  nixpkgs.config.allowUnfree = true;

  services.envfs.enable = true;
  
  # Blueman & Networking
  services.blueman.enable = true;
  services.resolved.enable = true;

  # Power Management & Battery Monitoring (Fixes WirePlumber warning)
  services.upower.enable = true;

  # Audio (PipeWire primary, PulseAudio explicitly disabled)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  hardware.pulseaudio.enable = false;

  # Default Shell & User Groups
  users.defaultUserShell = pkgs.zsh;
  users.users.nuser = {
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "audio" "bluetooth" ];
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

  # Security
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.gnome.gcr-ssh-agent.enable = false; # Fixes the assertion error

  # Modern SSH agent
  programs.ssh.startAgent = true;

  # System Packages
  environment.systemPackages = with pkgs; [
    tree
    bash 
    vim
    neovim
    git
    firefox
    brave
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
    tree-sitter
    gcc
    gnumake
    libnotify
    wlsunset
    unzip
    ripgrep
    fd
  ];

  fonts.packages = with pkgs; [
    font-awesome_4
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
    nerd-fonts.hack
    font-awesome
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "26.05";
}
