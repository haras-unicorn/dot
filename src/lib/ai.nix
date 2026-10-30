{ lib, ... }:

let
  assets = ../../assets/ai;
  skillsDir = assets + "/skills";
in
{
  self.lib.ai = {
    # NOTE: the global instructions both Claude Code and OpenCode load as context
    agents = builtins.readFile (assets + "/AGENTS.md");

    # NOTE: every markdown file in the skills folder is a skill named after the
    # file, and both tools install it as `<name>/SKILL.md`
    skills =
      lib.mapAttrs' (file: _: lib.nameValuePair (lib.removeSuffix ".md" file) (skillsDir + "/${file}"))
        (
          lib.filterAttrs (file: type: type == "regular" && lib.hasSuffix ".md" file) (
            builtins.readDir skillsDir
          )
        );
  };
}
