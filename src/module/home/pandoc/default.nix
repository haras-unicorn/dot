{ pkgs, ... }:

{
  programs.pandoc.enable = true;

  home.packages = with pkgs; [
    mermaid-filter
    pandoc-plantuml-filter
  ];
}
