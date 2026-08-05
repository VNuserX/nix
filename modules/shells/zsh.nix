{ config, pkgs, lib, ... }:

{
  options.modules.zsh = {
    enable = lib.mkEnableOption "Enable Zsh";
    powerlevel10k = lib.mkEnableOption "Enable Powerlevel10k theme";
  };

  config = let
    cfg = config.modules.zsh;
  in lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      zsh
      fzf
      zsh-autosuggestions
      zsh-syntax-highlighting
    ] ++ lib.optionals cfg.powerlevel10k [
      zsh-powerlevel10k
    ];

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      
      interactiveShellInit = let
        # Keybindings for word movement
        keybindings = ''
          # Fix Ctrl+Left/Right for word movement
          bindkey '^[[1;5C' forward-word
          bindkey '^[[1;5D' backward-word
        '';
        
        # Powerlevel10k setup
        p10kSetup = lib.optionalString cfg.powerlevel10k ''
          source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        '';
      in ''
        # Custom syntax highlighting styles
        ((''${+ZSH_HIGHLIGHT_STYLES})) || typeset -A ZSH_HIGHLIGHT_STYLES
        ZSH_HIGHLIGHT_STYLES[path]=none
        ZSH_HIGHLIGHT_STYLES[path_prefix]=none
        
        ${keybindings}
        
        # fzf setup
        source ${pkgs.fzf}/share/fzf/key-bindings.zsh
        source ${pkgs.fzf}/share/fzf/completion.zsh
        
        ${p10kSetup}
      '';
    };

    users.users.nuser = {
      shell = pkgs.zsh;
    };

    environment.shells = with pkgs; [ zsh ];
  };
}
