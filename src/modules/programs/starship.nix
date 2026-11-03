{
  self.homeModules.starship.value =
    { config, ... }:
    {
      programs.starship.enable = true;
      # NOTE: fails when trying to apply bright-yellow to color scheme
      stylix.targets.starship.enable = false;

      programs.starship.settings = config.dot.prompt.starship;
    };
}
