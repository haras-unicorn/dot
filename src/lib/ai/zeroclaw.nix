# NOTE: shell is ok because sandboxing and zeroclaw also parses it to check for
# allowed commands and disallows certain metacharacters

{
  self.lib.ai.zeroclaw = {
    config = {
      schema_version = 3;

      knowledge.enabled = true;

      verifiable_intent.enabled = true;

      link_enricher.enabled = true;

      gateway = {
        require_pairing = false;
        host = "127.0.0.1";
        port = 42617;
      };

      reliability = {
        provider_backoff_ms = 1000;
        provider_retries = 30;
      };
    };

    riskProfile = {
      level = "supervised";
      workspace_only = true;

      sandbox_backend = "bubblewrap";
      sandbox_enabled = true;

      # NOTE: touch is considered medium risk, for instance,
      # and we already have a sandbox
      # also there is a weird bug where the agent can't even ask
      # for approval because shell is in auto_approve right now
      require_approval_for_medium_risk = false;

      tool_receipts = {
        enabled = true;
        show_in_response = true;
      };
    };

    runtimeProfile = {
      max_tool_iterations = 100;
      max_actions_per_hour = 1000;
      max_history_messages = 64;
    };

    excludedTools = [
      "browser"
      "browser_open"
      "http_request"
      "proxy_config"

      "schedule"

      "screenshot"
      "pushover"
      "canvas"

      "model_switch"
      "model_routing_config"

      "memory_export"
      "memory_purge"

      "git_forge"
      "git_operations"

      "cron_add"
      "cron_remove"
      "cron_update"

      "TodoWrite"
      "llm_task"
      "project_intel"
      "report_template"
      "backup"
    ];

    chatTools = [
      "file_read"
      "file_write"
      "file_edit"

      "glob_search"
      "content_search"

      "cron_list"
      "cron_runs"

      "knowledge"
      "memory_store"
      "memory_recall"
      "memory_forget"

      "spawn_subagent"

      "pushover"
      "poll"
      "reaction"
      "ask_user"
      "send_via"
      "escalate_to_human"
      "channel_room"
      "vi_verify"

      "calculator"
      "weather"
      "image_info"

      "web_fetch"
      "web_search_tool"

      "sessions_current"
      "sessions_list"
      "sessions_history"
      "sessions_send"

      "mcp_resources"
      "mcp_prompts"
    ];

    delegateTools = [
      "file_read"
      "file_write"
      "file_edit"

      "glob_search"
      "content_search"

      "cron_list"
      "cron_run"
      "cron_runs"

      "knowledge"
      "memory_store"
      "memory_recall"
      "memory_forget"

      "spawn_subagent"
      "send_message_to_peer"
      "delegate"

      "pushover"
      "poll"
      "reaction"
      "ask_user"
      "send_via"
      "escalate_to_human"
      "channel_room"
      "vi_verify"

      "calculator"
      "weather"
      "image_info"

      "web_fetch"
      "web_search_tool"

      "sessions_current"
      "sessions_list"
      "sessions_history"
      "sessions_send"

      "mcp_resources"
      "mcp_prompts"
    ];

    digestTools = [
      "file_read"
      "file_write"
      "file_edit"

      "glob_search"
      "content_search"

      "knowledge"
      "memory_store"
      "memory_recall"

      "spawn_subagent"

      "calculator"
      "weather"
      "image_info"

      "web_fetch"
      "web_search_tool"

      "mcp_resources"
      "mcp_prompts"

      "rss__get_articles"
      "rss__fetch_article"
    ];

    devTools = [
      "shell"

      "file_read"
      "file_write"
      "file_edit"

      "glob_search"
      "content_search"

      "knowledge"
      "memory_store"
      "memory_recall"
      "memory_forget"

      "spawn_subagent"
      "send_message_to_peer"

      "vi_verify"

      "calculator"
      "weather"
      "image_info"

      "web_fetch"
      "web_search_tool"

      "mcp_resources"
      "mcp_prompts"

      "rss__get_articles"
      "rss__fetch_article"

      "nixos__nix"
      "nixos__nix_versions"

      "nix__nix_build"
      "nix__nix_run"
      "nix__nix_develop"
      "nix__nix_check"

      "git__git_init"
      "git__git_clone"
      "git__git_status"
      "git__git_clean"
      "git__git_add"
      "git__git_commit"
      "git__git_diff"
      "git__git_log"
      "git__git_show"
      "git__git_blame"
      "git__git_reflog"
      "git__git_changelog_analyze"
      "git__git_branch"
      "git__git_checkout"
      "git__git_merge"
      "git__git_rebase"
      "git__git_cherry_pick"
      "git__git_remote"
      "git__git_fetch"
      "git__git_pull"
      "git__git_push"
      "git__git_tag"
      "git__git_stash"
      "git__git_reset"
      "git__git_worktree"
      "git__git_set_working_dir"
      "git__git_clear_working_dir"
      "git__git_submodule"

      "github__actions_get"
      "github__actions_list"
      "github__get_job_logs"
      "github__get_me"
      "github__get_team_members"
      "github__get_teams"
      "github__discussion_comment_write"
      "github__get_discussion"
      "github__get_discussion_comments"
      "github__list_discussion_categories"
      "github__list_discussions"
      "github__add_issue_comment"
      "github__issue_read"
      "github__issue_write"
      "github__list_issue_fields"
      "github__list_issue_types"
      "github__search_issues"
      "github__sub_issue_write"
      "github__get_label"
      "github__label_write"
      "github__list_label"
      "github__dismiss_notification"
      "github__get_notification_details"
      "github__list_notifications"
      "github__manage_notification_subscription"
      "github__manage_repository_notification_subscription"
      "github__mark_all_notifications_read"
      "github__projects_get"
      "github__projects_list"
      "github__projects_write"
      "github__add_comment_to_pending_review"
      "github__add_reply_to_pull_request_comment"
      "github__create_pull_request"
      "github__list_pull_requests"
      "github__merge_pull_request"
      "github__pull_request_read"
      "github__pull_request_review_write"
      "github__search_pull_requests"
      "github__update_pull_request"
      "github__update_pull_request_branch"
      "github__create_branch"
      "github__create_repository"
      "github__fork_repository"
      "github__get_commit"
      "github__get_file_contents"
      "github__get_latest_release"
      "github__get_release_by_tag"
      "github__get_tag"
      "github__list_branches"
      "github__list_commits"
      "github__list_releases"
      "github__list_repository_collaborators"
      "github__list_tags"
      "github__search_code"
      "github__search_commits"
      "github__search_repositories"
      "github__list_starred_repositories"
      "github__star_repository"
      "github__unstar_repository"
      "github__search_users"
    ];

    allTools = [
      "shell"

      "file_read"
      "file_write"
      "file_edit"

      "glob_search"
      "content_search"

      "cron_list"
      "cron_run"
      "cron_runs"
      "cron_add"
      "cron_remove"
      "cron_update"

      "knowledge"
      "memory_store"
      "memory_recall"
      "memory_forget"

      "spawn_subagent"
      "send_message_to_peer"
      "delegate"

      "pushover"
      "TodoWrite"
      "report_template"
      "project_intel"
      "poll"
      "reaction"
      "ask_user"
      "send_via"
      "escalate_to_human"
      "channel_room"
      "vi_verify"

      "calculator"
      "weather"
      "canvas"
      "image_info"

      "web_fetch"
      "web_search_tool"

      "backup"

      "sessions_current"
      "sessions_list"
      "sessions_history"
      "sessions_send"

      "git_forge"
      "git_operations"

      "mcp_resources"
      "mcp_prompts"

      "rss__get_articles"
      "rss__fetch_article"

      "nixos__nix_versions"
      "nixos__nix"

      "nix__nix_run"
      "nix__nix_check"
      "nix__nix_build"
      "nix__nix_develop"

      "git__git_stash"
      "git__git_reflog"
      "git__git_pull"
      "git__git_push"
      "git__git_worktree"
      "git__git_add"
      "git__git_changelog_analyze"
      "git__git_rebase"
      "git__git_remote"
      "git__git_clear_working_dir"
      "git__git_reset"
      "git__git_cherry_pick"
      "git__git_init"
      "git__git_branch"
      "git__git_blame"
      "git__git_checkout"
      "git__git_merge"
      "git__git_show"
      "git__git_wrapup_instructions"
      "git__git_tag"
      "git__git_diff"
      "git__git_log"
      "git__git_clean"
      "git__git_fetch"
      "git__git_commit"
      "git__git_set_working_dir"
      "git__git_status"
      "git__git_clone"

      "github__get_label"
      "github__create_repository"
      "github__discussion_comment_write"
      "github__create_or_update_file"
      "github__get_tag"
      "github__list_branches"
      "github__list_issues"
      "github__get_discussion"
      "github__search_code"
      "github__search_commits"
      "github__create_pull_request"
      "github__pull_request_read"
      "github__update_pull_request_branch"
      "github__get_me"
      "github__label_write"
      "github__search_repositories"
      "github__projects_write"
      "github__actions_get"
      "github__actions_run_trigger"
      "github__delete_file"
      "github__add_reply_to_pull_request_comment"
      "github__list_starred_repositories"
      "github__add_issue_comment"
      "github__list_tags"
      "github__projects_get"
      "github__pull_request_review_write"
      "github__get_notification_details"
      "github__get_release_by_tag"
      "github__dismiss_notification"
      "github__actions_list"
      "github__mark_all_notifications_read"
      "github__push_files"
      "github__update_pull_request"
      "github__list_repository_collaborators"
      "github__list_discussions"
      "github__search_users"
      "github__sub_issue_write"
      "github__merge_pull_request"
      "github__get_commit"
      "github__get_job_logs"
      "github__manage_repository_notification_subscription"
      "github__unstar_repository"
      "github__get_latest_release"
      "github__issue_write"
      "github__list_label"
      "github__add_comment_to_pending_review"
      "github__list_pull_requests"
      "github__get_discussion_comments"
      "github__create_branch"
      "github__list_discussion_categories"
      "github__projects_list"
      "github__fork_repository"
      "github__list_notifications"
      "github__issue_read"
      "github__star_repository"
      "github__list_releases"
      "github__get_file_contents"
      "github__search_pull_requests"
      "github__search_issues"
      "github__list_commits"
      "github__manage_notification_subscription"
    ];
  };
}
