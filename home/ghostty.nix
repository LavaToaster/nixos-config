{ ... }:

{
  programs.ghostty = {
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
}
