{ config, pkgs, lib, ... }:

{
  options.modules.fzf = {
    enable = lib.mkEnableOption "Enable fzf with Zsh integration";
    enablePreviews = lib.mkEnableOption "Enable preview windows with bat";
  };

  config = let
    cfg = config.modules.fzf;
  in lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      fzf
    ] ++ lib.optionals cfg.enablePreviews [
      bat
    ];

    programs.zsh = {
      enable = true;
      
      interactiveShellInit = ''
        # Only source fzf if not already loaded
        if [[ -z "$FZF_LOADED" ]]; then
          export FZF_LOADED=1
          
          # Source fzf keybindings
          [ -f ${pkgs.fzf}/share/fzf/key-bindings.zsh ] && \
            source ${pkgs.fzf}/share/fzf/key-bindings.zsh
          [ -f ${pkgs.fzf}/share/fzf/completion.zsh ] && \
            source ${pkgs.fzf}/share/fzf/completion.zsh
          
          # FZF settings
          export FZF_DEFAULT_OPTS="--height 40% --border --inline-info"
          export FZF_CTRL_R_OPTS="--tac --height 40% --border --inline-info"
          
          ${lib.optionalString cfg.enablePreviews ''
            export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :500 {} 2>/dev/null || cat {}'"
          ''}
          
          # Fast aliases
          alias fh='history | fzf --tac'
          alias fkill='ps aux | fzf | awk "{print \$2}" | xargs kill -9'
          alias fcd='cd $(find . -type d -maxdepth 5 2>/dev/null | fzf)'
        fi
      '';
    };
  };
}
