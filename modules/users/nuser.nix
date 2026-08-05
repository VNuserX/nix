{ config, pkgs, lib, ... }:

{
  options.modules.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "nuser";
      description = "Main user name";
    };
    enable = lib.mkEnableOption "Create main user";
  };

  config = lib.mkIf config.modules.user.enable {
    users.users.${config.modules.user.name} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };

  };
}
