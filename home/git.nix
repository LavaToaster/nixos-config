{ userConfig, ... }:

let
  name = userConfig.name;
  email = userConfig.email;
in
{
  programs.git = {
    enable = true;
    ignores = [ "*.swp" "*.local.json" ];
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
}
