{
  self.lib.ai.openrouter = {
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
              # "parasail/fp8"
              # "coreweave/fp8"
              # "together"
            ];
            allow_fallbacks = false;
            require_parameters = true;
          };
        };
      };
      dev = {
        url = "https://openrouter.ai/api/v1";
        model = "meta/muse-spark-1.3-contributor";
        context = 1000 * 1000;
        costInCents = 10;
        costCachedCents = 2;
        costOutCents = 20;
        options = {
          temperature = 0.8;
          provider = {
            order = [
              "meta"
            ];
            allow_fallbacks = false;
            require_parameters = true;
          };
        };
      };
    };
  };
}
