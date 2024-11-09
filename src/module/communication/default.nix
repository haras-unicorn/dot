{ self, pkgs, lib, config, ... }:

# FIXME: screen sharing
# TODO: ferdium WebRTC handling - set share all IPs so discord WebRTC works
# NOTE: ferdium outlook - Self Hosted at https://outlook.office.com/mail/

let
  isLightTheme = config.dot.colors.isLightTheme;
  bootstrap = config.dot.colors.bootstrap;

  hasMonitor = config.dot.hardware.monitor.enable;

  ferdium = self.lib.electron.wrap pkgs pkgs.ferdium "ferdium";
  slack = self.lib.electron.wrap pkgs pkgs.slack "slack";
  teams = self.lib.electron.wrap pkgs pkgs.teams-for-linux "teams-for-linux";
  vesktop = self.lib.electron.wrap pkgs pkgs.vesktop "vesktop";
in
{
  shared = {
    dot = {
      desktopEnvironment.sessionStartup = lib.mkIf hasMonitor [
        "${ferdium}/bin/ferdium"
      ];
    };
  };

  home = lib.mkIf hasMonitor {
    home.packages = [
      ferdium
      teams
      vesktop
      slack
    ];

    xdg.configFile."Ferdium/config/settings.json".text = ''{
      "autoLaunchOnStart": false,
      "autoLaunchInBackground": false,
      "runInBackground": true,
      "reloadAfterResume": true,
      "reloadAfterResumeTime": 10,
      "enableSystemTray": true,
      "startMinimized": false,
      "confirmOnQuit": false,
      "minimizeToSystemTray": false,
      "closeToSystemTray": false,
      "privateNotifications": false,
      "clipboardNotifications": true,
      "notifyTaskBarOnMessage": false,
      "showDisabledServices": true,
      "isTwoFactorAutoCatcherEnabled": false,
      "twoFactorAutoCatcherMatcher": "token, code, sms, verify",
      "showServiceName": true,
      "showMessageBadgeWhenMuted": true,
      "showDragArea": false,
      "enableSpellchecking": true,
      "enableTranslator": false,
      "spellcheckerLanguage": "en-us",
      "darkMode": ${if isLightTheme then "true" else "false"},
      "navigationBarManualActive": true,
      "splitMode": false,
      "splitColumns": 3,
      "fallbackLocale": "en-US",
      "beta": false,
      "isAppMuted": false,
      "enableGPUAcceleration": true,
      "enableGlobalHideShortcut": false,
      "server": "You are using Ferdium without a server",
      "predefinedTodoServer": "https://todoist.com/app",
      "autohideMenuBar": true,
      "isLockingFeatureEnabled": false,
      "locked": false,
      "lockedPassword": "",
      "useTouchIdToUnlock": true,
      "scheduledDNDEnabled": false,
      "scheduledDNDStart": "17:00",
      "scheduledDNDEnd": "09:00",
      "hibernateOnStartup": true,
      "hibernationStrategy": 300,
      "wakeUpStrategy": 300,
      "wakeUpHibernationStrategy": 0,
      "wakeUpHibernationSplay": true,
      "inactivityLock": 0,
      "automaticUpdates": false,
      "universalDarkMode": true,
      "userAgentPref": "",
      "downloadFolderPath": "",
      "adaptableDarkMode": true,
      "accentColor": "${bootstrap.primary.normal.hex}",
      "progressbarAccentColor": "${bootstrap.primary.alternate.hex}",
      "serviceRibbonWidth": 68,
      "sidebarServicesLocation": 0,
      "iconSize": 20,
      "sentry": true,
      "navigationBarBehaviour": "always",
      "webRTCIPHandlingPolicy": "default",
      "searchEngine": "startPage",
      "translatorLanguage": "en",
      "translatorEngine": "LibreTranslate",
      "useHorizontalStyle": false,
      "hideCollapseButton": true,
      "isMenuCollapsed": false,
      "hideRecipesButton": true,
      "hideSplitModeButton": true,
      "useGrayscaleServices": false,
      "grayscaleServicesDim": 50,
      "hideWorkspacesButton": true,
      "hideNotificationsButton": true,
      "hideSettingsButton": false,
      "hideDownloadButton": false,
      "alwaysShowWorkspaces": false,
      "hideAllServicesWorkspace": false,
      "liftSingleInstanceLock": false,
      "enableLongPressServiceHint": false,
      "isTodosFeatureEnabled": false,
      "customTodoServer": "",
      "locale": "en-US",
      "keepAllWorkspacesLoaded": false,
      "useSelfSignedCertificates": false,
      "lockingFeatureEnabled": false
    }'';
  };
}
