{ selfLib, ... }:

{
  self.nixosConfigurations.gabi = {
    flake = true;

    value = {
      dot.hardware.deviceType = "wsl";

      dot.location = selfLib.location;
    };
  };
}
