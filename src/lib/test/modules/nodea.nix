{
  libAttrs.test.modules.nodea =
    { nodes, ... }:
    {
      _module.args.nodea = builtins.attrValues nodes;
    };
}
