{
  pkgs,
  lib,
  userConfig,
  ...
}:

let
  user = userConfig.username;
  sslCertFile = userConfig.sslCertFile or null;
in
{
  programs.zsh = {
    enable = true;
    autocd = true;
    cdpath = [ "~/Projects" ];

    setOptions = [
      "GLOBDOTS"
      "NO_CASEGLOB"
      "HIST_REDUCE_BLANKS"
      "HIST_VERIFY"
    ];

    history = {
      size = 10000000;
      save = 10000000;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = lib.cleanSource ../modules/shared/config;
        file = "p10k.zsh";
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "history-substring-search";
        src = pkgs.zsh-history-substring-search;
        file = "share/zsh-history-substring-search/zsh-history-substring-search.zsh";
      }
      {
        name = "fast-syntax-highlighting";
        src = pkgs.zsh-fast-syntax-highlighting;
        file = "share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh";
      }
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];
    initContent = lib.mkMerge [
      (lib.mkBefore (
        ''
          # p10k instant prompt
          if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
            source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
          fi

          # Brew completions (must be on fpath before compinit)
          if command -v brew &>/dev/null; then
            fpath+=($(brew --prefix)/share/zsh/site-functions)
          fi

          if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
            . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
            . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
          fi

          # PATH
          export PATH=$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH
          export PATH=$HOME/.npm-packages/bin:$HOME/bin:$PATH
          export PATH=$HOME/.local/bin:$HOME/.local/share/bin:$PATH
          export PATH=$HOME/.cargo/bin:$PATH


          # pnpm
          export PNPM_HOME="$HOME/.local/share/pnpm"
          case ":$PATH:" in
            *":$PNPM_HOME:"*) ;;
            *) export PATH="$PNPM_HOME:$PATH" ;;
          esac

          # Editors
          export EDITOR="nvim"
          export VISUAL="nvim"

          # Podman Docker compatibility
          export DOCKER_HOST="unix://$TMPDIR/podman/podman-machine-default-api.sock"

        ''
        + (
          if sslCertFile != null then
            ''
              # Point Node.js at the custom certificate bundle
              export NODE_EXTRA_CA_CERTS="${sslCertFile}"

              # Point Python/pip/pipx and general SSL at the custom certificate bundle
              export REQUESTS_CA_BUNDLE="${sslCertFile}"
              export SSL_CERT_FILE="${sslCertFile}"
              export PIP_CERT="${sslCertFile}"
            ''
          else
            ""
        )
        + ''

          # Reload shell
          alias rl="exec zsh -l"
          alias rll="rm -f $ZCOMPDUMP_PATH; rl"

          # Navigation aliases
          alias ..="cd .."
          alias ...="cd ../.."
          alias ....="cd ../../.."
          alias .....="cd ../../../.."
          alias c="clear"
          alias l='ls -lAh'

          # App aliases
          alias vi="nvim"
          alias vim="nvim"
          alias v="nvim"
          alias cat="bat --paging=never --theme=Dracula"
          # nix shortcuts
          shell() {
              nix-shell '<nixpkgs>' -A "$1"
          }
          alias rb="just -f $HOME/nixos-config/justfile switch"

          # Package manager aliases
          alias pn=pnpm
          alias px=pnpx

          # Use difftastic, syntax-aware diffing
          alias diff=difft

          # Ripgrep alias
          alias search="rg -p --glob '!node_modules/*'"

          alias ports="lsof -iTCP -sTCP:LISTEN -P"



          # Compatibility aliases
          alias terraform=tofu
          alias docker=podman
          alias docker-compose=podman-compose

          alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder"

          # Completion styles
          zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
          # Prevent fzf-tab from using typed input (e.g. "home/") as the fzf query, which filters out all results
          zstyle ':fzf-tab:*' query-string prefix

          if [ -n "''${TMUX}" ]; then
            zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
          fi

          # Keybindings
          zmodload zsh/terminfo

          typeset -A key
          key[Home]=''${terminfo[khome]}
          key[End]=''${terminfo[kend]}
          key[Insert]=''${terminfo[kich1]}
          key[Delete]=''${terminfo[kdch1]}
          key[Up]=''${terminfo[kcuu1]}
          key[Down]=''${terminfo[kcud1]}
          key[Left]=''${terminfo[kcub1]}
          key[Right]=''${terminfo[kcuf1]}
          key[Alt-Left]=''${terminfo[kLFT3]}
          key[Alt-Right]=''${terminfo[kRIT3]}
          key[PageUp]=''${terminfo[kpp]}
          key[PageDown]=''${terminfo[knp]}

          if (( ''${+terminfo[smkx]} )) && (( ''${+terminfo[rmkx]} )); then
            function zle-line-init() { echoti smkx }
            function zle-line-finish() { echoti rmkx }
            zle -N zle-line-init
            zle -N zle-line-finish
          fi

          bindkey -e

          [[ -n "''${key[Home]}"      ]] && bindkey "''${key[Home]}"      beginning-of-line
          [[ -n "''${key[End]}"       ]] && bindkey "''${key[End]}"       end-of-line
          [[ -n "''${key[Insert]}"    ]] && bindkey "''${key[Insert]}"    overwrite-mode
          [[ -n "''${key[Delete]}"    ]] && bindkey "''${key[Delete]}"    delete-char
          [[ -n "''${key[Up]}"        ]] && bindkey "''${key[Up]}"        history-substring-search-up
          [[ -n "''${key[Down]}"      ]] && bindkey "''${key[Down]}"      history-substring-search-down
          [[ -n "''${key[Left]}"      ]] && bindkey "''${key[Left]}"      backward-char
          [[ -n "''${key[Right]}"     ]] && bindkey "''${key[Right]}"     forward-char
          [[ -n "''${key[Alt-Left]}"  ]] && bindkey "''${key[Alt-Left]}"  backward-word
          [[ -n "''${key[Alt-Right]}" ]] && bindkey "''${key[Alt-Right]}" forward-word
          bindkey "^[[1;9D" backward-word
          bindkey "^[[1;9C" forward-word
          bindkey "^[^[[D" backward-word
          bindkey "^[^[[C" forward-word
          bindkey '^[^?' backward-kill-word

          # fzf integration (Ctrl+R history search, Ctrl+T file search, Alt+C cd)
          if [[ -f "${pkgs.fzf}/share/fzf/key-bindings.zsh" ]]; then
            source "${pkgs.fzf}/share/fzf/key-bindings.zsh"
          fi
        ''
        + (
          let
            p = let su = builtins.getEnv "SUDO_USER"; u = if su != "" then su else builtins.getEnv "USER"; in "/Users/" + u + "/nixos-private/shell.nix";
          in
          if builtins.pathExists p then import p { inherit pkgs; } else ""
        )
      ))
      (lib.mkAfter ''
        # Completions (must run after compinit)
        if [[ -f "${pkgs.fzf}/share/fzf/completion.zsh" ]]; then
          source "${pkgs.fzf}/share/fzf/completion.zsh"
        fi
        source <(kubie generate-completion)

        # aws completions (uses bash-style completer)
        if command -v aws_completer &>/dev/null; then
          autoload bashcompinit && bashcompinit
          complete -C aws_completer aws
        fi
      '')
    ];
  };
}
