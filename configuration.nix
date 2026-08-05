{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./modules/users/nuser.nix
    ./modules/shells/zsh.nix
    ./modules/tools/fzf.nix
    ./modules/desktop/sway.nix
    ./modules/services/pipewire.nix
  ];

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

  # Bluetooth hardware - enhanced
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        # Auto-detect and connect
        AutoConnect = "true";
        # Better audio support
        MultiProfile = "multiple";
      };
    };
  };

  # Since you already have pipewire module, ensure it has bluetooth support
  # Check your ./modules/services/pipewire.nix file
  # It should include:
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  # Blueman service
  services.blueman.enable = true;

  # Audio group for your user
  users.users.nuser = {
    extraGroups = [ "audio" "bluetooth" ];
  };

   programs.dconf = {
     enable = true;
     profiles.user.databases = [{
       settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
     }];
   };
  # Core system settings
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-nuser";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Riga";

  # Security
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # Applications
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
