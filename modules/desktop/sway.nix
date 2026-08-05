{ config, pkgs, lib, ... }:

{
  options.modules.sway = {
    enable = lib.mkEnableOption "Enable Sway window manager";
    autologin = lib.mkEnableOption "Auto-login to Sway on tty1";
  };

config = lib.mkIf config.modules.sway.enable {
  programs.sway.enable = true;
  nixpkgs.config.allowUnfree = true;
  services.getty = lib.mkIf config.modules.sway.autologin {
    autologinUser = "nuser";
    autologinOnce = false;
  };

  environment.loginShellInit = lib.mkIf config.modules.sway.autologin ''
    [[ "$(tty)" == /dev/tty1 ]] && sway
  '';

  environment.systemPackages = with pkgs; [
    foot
    waybar
    swaybg
    swayidle
    swaylock
    grim
    slurp
    wl-clipboard
    mako
    wdisplays
    wlr-randr

    # Development
    bun
    gnumake
    go
    (lua.withPackages (ps: [ps.cjson]))
    nixfmt
    nodejs
    perl
    perl5Packages.Carton
    python3
    uv
    rustup
    slack
    google-cloud-sdk
    # Kubernetes
    kubectl
    kubectl-view-secret
    kubectx
    kubernetes-helm

  ];
};
}
