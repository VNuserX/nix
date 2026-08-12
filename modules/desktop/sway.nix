{ config, lib, pkgs, ... }:

{
  options.modules.sway = {
    enable = lib.mkEnableOption "Enable Sway window manager";
    autologin = lib.mkEnableOption "Enable autologin for Sway";
  };

  config = lib.mkIf config.modules.sway.enable {
    # 1. Enable Twingate background daemon (autostart disabled)
    services.twingate.enable = true;
    systemd.services.twingate.wantedBy = lib.mkForce [ ];

    # 2. Auto-login setup
    services.getty = lib.mkIf config.modules.sway.autologin {
      autologinUser = "nuser";
      autologinOnce = false;
    };

    environment.loginShellInit = lib.mkIf config.modules.sway.autologin ''
      [[ "$(tty)" == /dev/tty1 ]] && sway
    '';

    # 3. Declarative Kanshi Docking Configuration
    environment.etc."kanshi/config".text = ''
      # Profile 1: Undocked (Laptop only when on the move)
      profile undocked {
          output eDP-1 enable mode 1920x1200@60.001Hz position 0,0 scale 1.0
      }

      # Profile 2: Docked Triple Screen (J16XDM3 is Left, JYRXDM3 is Right)
      profile docked-triple {
          output "*J16XDM3*" mode 2560x1440@59.951Hz position 0,0 scale 1.0
          output "*JYRXDM3*" mode 2560x1440@59.951Hz position 2560,0 scale 1.0
          output eDP-1 enable mode 1920x1200@60.001Hz position 5120,0 scale 1.0
      }

      # Profile 3: Docked Dual Screen (Laptop lid closed)
      profile docked-dual {
          output "*J16XDM3*" mode 2560x1440@59.951Hz position 0,0 scale 1.0
          output "*JYRXDM3*" mode 2560x1440@59.951Hz position 2560,0 scale 1.0
          output eDP-1 disable
      }
    '';

    # 4. Enable Sway Window Manager
    programs.sway.enable = true;

    # 5. System Packages
    environment.systemPackages = with pkgs; [
      # Display & Wayland Tools
      kanshi    # Dynamic output daemon for docking
      wdisplays
      wlr-randr
      foot
      waybar
      swaybg
      swayidle
      swaylock
      grim
      slurp
      wl-clipboard
      mako

      # Development Tools
      jq
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
      stern
      viddy
      slack
      rclone
      # Kubernetes & Cloud Infrastructure
      kubectl
      kubectl-view-secret
      kubectx
      kubernetes-helm
      terraform
      tenv
      talosctl
      direnv
      kubectl-cnpg
      google-cloud-sdk
      (google-cloud-sdk.withExtraComponents [
        google-cloud-sdk.components.gke-gcloud-auth-plugin
      ])
    ];
  };
}
