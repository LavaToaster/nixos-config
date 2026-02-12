{ ... }:

{
  programs.zed-editor = {
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

}
