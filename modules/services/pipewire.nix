{ config, pkgs, lib, ... }:

{
  options.modules.pipewire = {
    enable = lib.mkEnableOption "Enable Pipewire audio";
    pulse = lib.mkEnableOption "Enable PulseAudio compatibility";
  };

  config = lib.mkIf config.modules.pipewire.enable {
    services.pipewire = {
      enable = true;
      pulse.enable = config.modules.pipewire.pulse;
    };
  };
}
