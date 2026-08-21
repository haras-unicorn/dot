{
  self.lib.ai.openrouter = {
    model = "deepseek/deepseek-v4-flash-0731";
    context = 1000 * 1000;
    options = {
      provider = {
        only = [
          "relace/fp4"
          "deepinfra/fp8"
          "coreweave/fp8"
          "novita/fp8"
        ];
        allow_fallbacks = false;
      };
    };
  };
}
