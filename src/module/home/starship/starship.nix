{ ... }:

{
  programs.starship.enable = true;
  programs.starship.settings = builtins.fromTOML (builtins.readFile ./starship.toml);

  # programs.starship.enableNushellIntegration = true;
}
