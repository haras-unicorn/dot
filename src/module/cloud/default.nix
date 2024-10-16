{ pkgs
, ...
}:

# FIXME: azure-cli: fabric: ModuleNotFoundError: No module named 'nacl'

{
  home.shared = {
    home.packages = with pkgs; [
      (azure-cli.withExtensions (with pkgs; [
        azure-cli-extensions.ssh
      ]))
    ];

    home.file.".azure/config".source = ./azure-config;
  };
}
