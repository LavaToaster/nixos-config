{
  config,
  pkgs,
  lib,
  userConfig,
  ...
}:

let
  name = userConfig.name;
  user = userConfig.username;
  email = userConfig.email;
  sslCertFile = userConfig.sslCertFile or null;
in
{
  # Shared shell configuration
  zsh = {
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
        src = lib.cleanSource ./config;
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
          export PATH=$HOME/.local/share/bin:$PATH
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

        ''
        + (
          if sslCertFile != null then
            ''
              # Point Node.js at the custom certificate bundle
              export NODE_EXTRA_CA_CERTS="${sslCertFile}"
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
          alias rebuild="just -f $HOME/nixos-config/justfile switch"

          # Package manager aliases
          alias pn=pnpm
          alias px=pnpx

          # Use difftastic, syntax-aware diffing
          alias diff=difft

          # Ripgrep alias
          alias search="rg -p --glob '!node_modules/*'"

          # Always color ls and group directories
          alias ls='ls --color=auto'

          # Docker
          dkillall() {
            docker kill $(docker ps -q)
          }

          alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder"

          # Completion styles
          zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

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

  git = {
    enable = true;
    ignores = [ "*.swp" ];
    lfs = {
      enable = true;
    };
    settings = {
      user = {
        name = name;
        email = email;
      };
      alias = {
        s = "status -s";
        l = "log --pretty=oneline -n 20 --graph";
        lg = "log --graph --stat --pretty=format:'%C(yellow bold)%h%Creset%C(white)%d%Creset %s%n %C(blue)%aN (%cd)%n'";
        pushf = "push --force-with-lease";
        recent = "for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'";
        main = "!git fetch origin main:main && git checkout main";
        master = "!git fetch origin master:master && git checkout master";
        move = "!f() { git checkout -b $1 && git checkout - && git reset --hard HEAD~1 && git checkout - ; }; f";
      };
      init.defaultBranch = "main";
      core = {
        editor = "nvim";
        autocrlf = "input";
        pager = "diff-so-fancy | less --tabs=4 -RFX";
        excludesfile = "~/.gitignore";
      };
      commit.gpgsign = true;
      pull.rebase = true;
      push.autoSetupRemote = true;
      rebase.autoStash = true;
      merge.ff = false;
      color = {
        ui = true;
        diff = {
          frag = "magenta bold";
          meta = "yellow";
          new = "green bold";
          old = "red bold";
          commit = "yellow bold";
          whitespace = "red reverse";
        };
        diff-highlight = {
          oldNormal = "red bold";
          oldHighlight = "red bold 52";
          newNormal = "green bold";
          newHighlight = "green bold 22";
        };
      };
    };
  };

  zed-editor = {
    enable = true;
    package = null; # installed via Homebrew

    extensions = [
      "base16"
      "bearded-icon-theme"
      "csharp"
      "dockerfile"
      "git-firefly"
      "helm"
      "html"
      "nix"
      "rego"
      "starlark"
    ];

    userSettings = {
      icon_theme = "Bearded Icon Theme";
      buffer_font_family = "FiraCode Nerd Font Mono";
      ui_font_size = 16;
      buffer_font_size = 15;
      theme = {
        mode = "system";
        light = "One Light";
        dark = "Base16 Tomorrow Night Eighties";
      };
      autosave = "on_focus_change";
      file_scan_exclusions = ["**/.history/**"];
    };

    userKeymaps = [
      {
        context = "!ContextEditor > (Editor && mode == full)";
        bindings = {
          "cmd-shift-space" = "editor::ToggleInlayHints";
        };
      }
    ];
  };

  ghostty = {
    enable = true;
    package = null; # installed via Homebrew

    settings = {
      theme = "Dark Modern";
      keybind = [
        "cmd+left=previous_tab"
        "cmd+right=next_tab"
        "shift+enter=text:\n"
      ];

      window-padding-x = 2;
      window-padding-y = 2;
    };
  };

  ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "/Users/${user}/.ssh/config_external"
    ];
    matchBlocks = {
      "*" = {
        # Set the default values we want to keep
        sendEnv = [
          "LANG"
          "LC_*"
        ];
        hashKnownHosts = true;
      };
      "github.com" = {
        identitiesOnly = true;
        identityFile = [
          "/Users/${user}/.ssh/id_github"
        ];
      };
    };
  };

  tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      sensible
      yank
      prefix-highlight
      {
        plugin = power-theme;
        extraConfig = ''
          set -g @tmux_power_theme 'gold'
        '';
      }
      {
        plugin = resurrect; # Used by tmux-continuum

        # Use XDG data directory
        # https://github.com/tmux-plugins/tmux-resurrect/issues/348
        extraConfig = ''
          set -g @resurrect-dir '$HOME/.cache/tmux/resurrect'
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-pane-contents-area 'visible'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '5' # minutes
        '';
      }
    ];
    terminal = "screen-256color";
    prefix = "C-x";
    escapeTime = 10;
    historyLimit = 50000;
    extraConfig = ''
      # Remove Vim mode delays
      set -g focus-events on

      # Enable full mouse support
      set -g mouse on

      # -----------------------------------------------------------------------------
      # Key bindings
      # -----------------------------------------------------------------------------

      # Unbind default keys
      unbind C-b
      unbind '"'
      unbind %

      # Split panes, vertical or horizontal
      bind-key x split-window -v
      bind-key v split-window -h

      # Move around panes with vim-like bindings (h,j,k,l)
      bind-key -n M-k select-pane -U
      bind-key -n M-h select-pane -L
      bind-key -n M-j select-pane -D
      bind-key -n M-l select-pane -R

      # Smart pane switching with awareness of Vim splits.
      # This is copy paste from https://github.com/christoomey/vim-tmux-navigator
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
        | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
      bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
      tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
      if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
      if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R
      bind-key -T copy-mode-vi 'C-\' select-pane -l
    '';
  };
}
