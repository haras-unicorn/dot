// no weird margins around websites
user_pref("privacy.resistFingerprinting.letterboxing", false);

// no bookmarks bar
user_pref("browser.toolbars.bookmarks.visibility", "never");

// dumbass icon
user_pref("extensions.pocket.enabled", false);

// disable the would you like to save the login credentials prompt
user_pref("signon.rememberSignons", false);

// keep history
user_pref("privacy.clearOnShutdown.history", false);

// suggest search
user_pref("browser.search.suggest.enabled", true);

// remember logins
user_pref("privacy.clearOnShutdown.cookies", false);
user_pref("privacy.clearOnShutdown.offlineApps", false);

// use download directory
user_pref("browser.download.useDownloadDir", true);

// hardware acceleration
user_pref("webgl.disabled", false);
user_pref("gfx.webrender.all", true);
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("media.hardware-video-decoding.force-enabled", true);

// resistFingerprinting overrides fingerprintingProtection, so these must be disabled
user_pref("privacy.resistFingerprinting", false);
user_pref("privacy.resistFingerprinting.pbmode", false);

// At least one of these two must be enabled
user_pref("privacy.fingerprintingProtection", true);
user_pref("privacy.fingerprintingProtection.pbmode", true);

user_pref("privacy.fingerprintingProtection.overrides", "+AllTargets,-CSSPrefersColorScheme,-WebGLRenderCapability");
