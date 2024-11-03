{ self, ... }:

{
  user = "haras";
  version = "24.11";
  modules = builtins.attrValues (self.lib.import.importDir "${self}/src/module");
}
