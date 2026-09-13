{
  self.lib.openrouter = {
    profiles = {
      default = {
        url = "https://openrouter.ai/api/v1";
        model = "deepseek/deepseek-v4.1-flash";
        context = 1000 * 1000;
        costInCents = 20;
        costCachedCents = 1;
        costOutCents = 60;
        options = {
          temperature = 0.8;
          provider = {
            order = [
              "relace/fp4"
              "deepinfra/fp8"
              "azure"
            ];
            allow_fallbacks = false;
            require_parameters = true;
          };
        };
      };
      dev = {
        url = "https://openrouter.ai/api/v1";
        model = "deepseek/deepseek-v4.1-flash";
        context = 1000 * 1000;
        costInCents = 20;
        costCachedCents = 1;
        costOutCents = 60;
        options = {
          temperature = 0.8;
          provider = {
            order = [
              "relace/fp4"
              "deepinfra/fp8"
              "azure"
            ];
            allow_fallbacks = false;
            require_parameters = true;
          };
        };
      };
    };
  };
}
