{ ... }:

{
  programs.tealdeer.enable = true;
  programs.tealdeer.settings = {
    updates = {
      auto_update = true;
    };
  };
}
