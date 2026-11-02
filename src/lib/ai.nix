{ lib, ... }:

let
  assets = ../../assets/ai;
  skillsDir = assets + "/skills";
in
{
  self.lib.ai = {
    agents = builtins.readFile (assets + "/AGENTS.md");

    skills =
      lib.mapAttrs' (file: _: lib.nameValuePair (lib.removeSuffix ".md" file) (skillsDir + "/${file}"))
        (
          lib.filterAttrs (file: type: type == "regular" && lib.hasSuffix ".md" file) (
            builtins.readDir skillsDir
          )
        );
  };
}
