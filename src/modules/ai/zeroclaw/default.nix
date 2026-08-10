        runtime_profiles.main = {
          max_tool_iterations = 100;
          # NOTE: schema default is far lower and shared with subagents;
          # 1000/hour is effectively frictionless, u32::MAX is truly unlimited
          max_actions_per_hour = 1000;
        };
