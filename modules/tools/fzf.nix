{ config, pkgs, lib, ... }:

{
  options.modules.fzf = {
    enable = lib.mkEnableOption "Enable fzf with Zsh integration";
    enablePreviews = lib.mkEnableOption "Enable preview windows with bat";
  };

  config = let
    cfg = config.modules.fzf;
  in lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.fzf
    ] ++ lib.optional cfg.enablePreviews pkgs.bat;

    programs.zsh = {
      enable = true;

      # lib.mkAfter ensures this runs AFTER zsh.nix's bindkey -e
      interactiveShellInit = lib.mkAfter ''
        # Modern FZF Zsh integration (loads completions & Ctrl+R / Ctrl+T)
        eval "$(${pkgs.fzf}/bin/fzf --zsh)"

        # FZF settings
        export FZF_DEFAULT_OPTS="--height 40% --border --inline-info"
        export FZF_CTRL_R_OPTS="--tac --height 40% --border --inline-info"

        ${lib.optionalString cfg.enablePreviews ''
          export FZF_CTRL_T_OPTS="--preview '${pkgs.bat}/bin/bat --color=always --line-range :500 {} 2>/dev/null || cat {}'"
        ''}

        # Fast aliases
        alias fh='history | fzf --tac'
        alias fkill='ps aux | fzf | awk "{print \$2}" | xargs kill -9'

        # Safe fcd: Only changes directory if a selection was actually made
        fcd() {
          local dir
          dir=$(find . -type d -maxdepth 5 2>/dev/null | fzf) && cd "$dir"
        }
      '';
    };
  };
}
