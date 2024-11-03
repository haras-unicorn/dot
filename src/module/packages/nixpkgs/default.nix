{ nix-vscode-extensions, config, ... }:

let
  graphicsCardDriver = config.facter.report.hardware.graphics_card.driver;
in
{
  shared = {
    nixpkgs.config = {
      allowUnfree = true;
      cudaSupport = graphicsCardDriver == "nvidia";
      rocmSupport = graphicsCardDriver == "amdgpu";
    };
    nixpkgs.overlays = [
      nix-vscode-extensions.overlays.default
    ];
  };
}
