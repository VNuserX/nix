{ config, lib, pkgs, ... }:

let
  cfg = config.modules.zsh;
in
{
  options.modules.zsh = {
    enable = lib.mkEnableOption "Enable Zsh shell";
    powerlevel10k = lib.mkEnableOption "Enable Powerlevel10k theme";
  };

  config = lib.mkIf cfg.enable {
    # fzf-tab package removed; only install p10k if enabled
    environment.systemPackages = lib.optional cfg.powerlevel10k pkgs.zsh-powerlevel10k;

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      promptInit = lib.mkIf cfg.powerlevel10k ''
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      '';

      interactiveShellInit = ''
        # 1. Reset to standard Emacs keymap (locks in Ctrl+A / Ctrl+E)
        bindkey -e

        # 2. Disable path underlining from syntax highlighting
        typeset -A ZSH_HIGHLIGHT_STYLES
        ZSH_HIGHLIGHT_STYLES[path]='none'
        ZSH_HIGHLIGHT_STYLES[path-prefix]='none'
        ZSH_HIGHLIGHT_STYLES[autocd]='none'

        # 3. Native Zsh completion menu (navigable with Arrow Keys / Tab)
        zstyle ':completion:*' menu select

        # 4. Native case-insensitive & substring matching (works on cd ../ingress)
        zstyle ':completion:*' matcher-list "" 'm:{a-zA-Z}={A-Za-z}' 'm:{a-zA-Z}={A-Za-z} l:|=* r:|=*'

        # 5. Reliable navigation & word jumping shortcuts
        bindkey '^A' beginning-of-line
        bindkey '^E' end-of-line
        bindkey '^[[H' beginning-of-line
        bindkey '^[[F' end-of-line
        bindkey '^[[1;5D' backward-word
        bindkey '^[[1;5C' forward-word
        bindkey '^H' backward-kill-word
        bindkey '^[[3;5~' kill-word

        # 6. Load Powerlevel10k config if present
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

        # for autocomplete view-secret
        source <(kubectl completion zsh)
        alias k=kubectl
        compdef __start_kubectl k
      '';
    };
  };
}
