{
  self.nixosModules.impermanence.value = {
    boot.tmp.cleanOnBoot = true;
  };
}
