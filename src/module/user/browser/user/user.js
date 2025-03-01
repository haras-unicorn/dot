// ----------------------------------------------------------------------------
// PREFERENCES
// ----------------------------------------------------------------------------

// do not show warning on about:config
user_pref("browser.aboutConfig.showWarning", false);

// set blank page on startup, home, new tab
user_pref("browser.startup.page", 0);
user_pref("browser.startup.homepage", "about:blank");
user_pref("browser.newtabpage.enabled", false);

// set language to us english
user_pref("intl.accept_languages", "en-US, en");
user_pref("javascript.use_us_english_locale", true);

// disable automatic restart on reboot
user_pref("toolkit.winRegisterApplicationRestart", false);

// set devtools to right
user_pref("devtools.toolbox.host", "right");

// remove pocket icon
user_pref("extensions.pocket.enabled", false);

// disable welcome
user_pref("browser.startup.homepage_override.mstone", "ignore");

// disable whats new
user_pref("browser.messaging-system.whatsNewPanel.enabled", false);

// zoom
user_pref("layout.css.devPixelsPerPx", "1.5");

// disable default browser dialog
user_pref("browser.shell.checkDefaultBrowser", false);

// search suggestions
user_pref("browser.search.suggest.enabled", true);
user_pref("browser.urlbar.suggest.history", true);
user_pref("browser.urlbar.suggest.searches", true);
user_pref("browser.urlbar.suggest.recentsearches", true);
user_pref("browser.urlbar.suggest.engines", true);
user_pref("browser.urlbar.suggest.addons", false);
user_pref("browser.urlbar.suggest.bookmark", false);
user_pref("browser.urlbar.suggest.calculator", false);
user_pref("browser.urlbar.suggest.clipboard", false);
user_pref("browser.urlbar.suggest.fakespot", false);
user_pref("browser.urlbar.suggest.mdn", false);
user_pref("browser.urlbar.suggest.openpage", false);
user_pref("browser.urlbar.suggest.pocket", false);
user_pref("browser.urlbar.suggest.quickactions", false);
user_pref("browser.urlbar.suggest.remotetab", false);
user_pref("browser.urlbar.suggest.topsites", false);
user_pref("browser.urlbar.suggest.trending", false);
user_pref("browser.urlbar.suggest.weather", false);
user_pref("browser.urlbar.suggest.yelp", false);

// keep logins, history, site settings, cookies
user_pref("privacy.clearOnShutdown.cookies", false);
user_pref("privacy.clearOnShutdown.sessions", false);
user_pref("privacy.clearOnShutdown.siteSettings", false);
user_pref("privacy.clearOnShutdown_v2.cookiesAndStorage", false);
user_pref("privacy.clearOnShutdown_v2.siteSettings", false);
user_pref("privacy.clearOnShutdown.history", false);

// ----------------------------------------------------------------------------
// HARDENING
// concerned with how certain protocols behave
// if something breaks start by commenting out this entire section
// ----------------------------------------------------------------------------

// windows
user_pref("security.family_safety.mode", 0);
user_pref("network.http.windows-sso.enabled", false);
user_pref("network.protocol-handler.external.ms-windows-store", false);

// ssl
user_pref("security.ssl.require_safe_negotiation", true);
user_pref("security.tls.enable_0rtt_data", false);
user_pref("security.OCSP.enabled", 1);
user_pref("security.OCSP.require", true);
user_pref("security.cert_pinning.enforcement_level", 2);
user_pref("security.remote_settings.crlite_filters.enabled", true);
user_pref("security.pki.crlite_mode", 2);
user_pref("dom.security.https_only_mode", true);
user_pref("dom.security.https_only_mode_send_http_background_request", false);
user_pref("security.ssl.treat_unsafe_negotiation_as_broken", true);
user_pref("browser.xul.error_pages.expert_bad_cert", true);
user_pref("security.tls.version.enable-deprecated", false);
user_pref("security.tls.version.min", 3);
user_pref("security.tls.version.max", 4);
user_pref("security.ssl.disable_session_identifiers", true);

// cipher
user_pref("security.ssl3.ecdhe_ecdsa_aes_128_sha", false);
user_pref("security.ssl3.ecdhe_ecdsa_aes_256_sha", false);
user_pref("security.ssl3.ecdhe_rsa_aes_128_sha", false);
user_pref("security.ssl3.ecdhe_rsa_aes_256_sha", false);
user_pref("security.ssl3.rsa_aes_128_gcm_sha256", false);
user_pref("security.ssl3.rsa_aes_256_gcm_sha384", false);
user_pref("security.ssl3.rsa_aes_128_sha", false);
user_pref("security.ssl3.rsa_aes_256_sha", false);

// webrtc
user_pref("media.peerconnection.ice.proxy_only_if_behind_proxy", true);
user_pref("media.peerconnection.ice.default_address_only", true);
user_pref("media.peerconnection.ice.no_host", true);
user_pref("media.gmp-provider.enabled", false);
user_pref("media.gmp-widevinecdm.enabled", false);
user_pref("media.eme.enabled", false);
user_pref("browser.eme.ui.enabled", false);

// dom
user_pref("dom.disable_window_move_resize", true);

// geolocation
user_pref("geo.enabled", false);
user_pref("geo.provider.network.url", "");
user_pref("geo.provider.ms-windows-location", false);
user_pref("geo.provider.use_corelocation", false);
user_pref("geo.provider.use_gpsd", false);
user_pref("geo.provider.use_geoclue", false);

// webchannel
user_pref("webchannel.allowObject.urlWhitelist", "");

// pdfjs
user_pref("pdfjs.enableScripting", false);

// ui tour
user_pref("browser.uitour.enabled", false);

// extensions
user_pref("extensions.enabledScopes", 5);
user_pref("extensions.autoDisableScopes", 15);
user_pref("extensions.postDownloadThirdPartyPrompt", false);
user_pref("extensions.blocklist.enabled", true);
user_pref("extensions.webcompat.enable_shims", true);
user_pref("extensions.systemAddon.update.enabled", false);
user_pref("extensions.systemAddon.update.url", "");

// permissions
user_pref("permissions.manager.defaultsUrl", "");
user_pref("permissions.delegation.enabled", false);
user_pref("permissions.default.geo", 2);
user_pref("permissions.default.desktop-notification", 2);
user_pref("permissions.default.xr", 2);

// notifications
user_pref("dom.webnotifications.enabled", false);
user_pref("dom.webnotifications.serviceworker.enabled", false);
user_pref("dom.push.enabled", false);

// fingerprinting
user_pref("privacy.fingerprintingProtection", true);
user_pref("privacy.fingerprintingProtection.pbmode", true);
user_pref(
  "privacy.fingerprintingProtection.overrides",
  "+AllTargets"
    // enable system color scheme detection
    + ",-CSSPrefersColorScheme"
    // enable gpu rendering
    + ",-WebGLRenderCapability"
    // disable canvas randomization
    + ",-CanvasRandomization");
user_pref("browser.link.open_newwindow", 3);
user_pref("browser.link.open_newwindow.restriction", 0);

// miscellaneous
user_pref("network.http.referer.XOriginTrimmingPolicy", 2);
user_pref("devtools.debugger.remote-enabled", false);
user_pref("network.http.referer.spoofSource", false);
user_pref("security.dialog_enable_delay", 1000);
user_pref("privacy.firstparty.isolate", false);
user_pref("extensions.webcompat.enable_shims", true);
user_pref("accessibility.force_disabled", 1);
user_pref("extensions.webcompat-reporter.enabled", false);
user_pref("dom.event.contextmenu.enabled", false);

// ----------------------------------------------------------------------------
// PRIVACY
// concerned with what firefox does
// ----------------------------------------------------------------------------

// disabled sponsored firefox content
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);

// disable recommendations
user_pref("extensions.getAddons.showPane", false);
user_pref("extensions.htmlaboutaddons.recommendations.enabled", false);
user_pref("browser.discovery.enabled", false);

// disable telemetry
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.server", "data:,");
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);
user_pref("toolkit.telemetry.coverage.opt-out", true);
user_pref("toolkit.coverage.opt-out", true);
user_pref("toolkit.coverage.endpoint.base", "");
user_pref("browser.ping-centre.telemetry", false);
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
user_pref("browser.newtabpage.activity-stream.telemetry", false);

// disable studies
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("app.normandy.enabled", false);
user_pref("app.normandy.api_url", "");

// disable crash reports
user_pref("breakpad.reportURL", "");
user_pref("browser.tabs.crashReporting.sendReport", false);
user_pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);

// disable other telemetry
user_pref("captivedetect.canonicalURL", "");
user_pref("network.captive-portal-service.enabled", false);
user_pref("network.connectivity-service.enabled", false);

// dont leak search stuff
user_pref("keyword.enabled", false);
user_pref("browser.fixup.alternate.enabled", false);
user_pref("browser.urlbar.speculativeConnect.enabled", false);
user_pref("browser.urlbar.dnsResolveSingleWordsAfterSearch", 0);
user_pref("browser.urlbar.suggest.quicksuggest.nonsponsored", false);
user_pref("browser.urlbar.suggest.quicksuggest.sponsored", false);
user_pref("browser.urlbar.showSearchTerms.enabled", false);

// disable form capture and filling
user_pref("browser.formfill.enable", false);
user_pref("signon.autofillForms", false);
user_pref("signon.formlessCapture.enabled", false);
user_pref("signon.rememberSignons", false);

// disable disk cache
user_pref("browser.privatebrowsing.forceMediaMemoryCache", true);

// tracking protection
user_pref("browser.contentblocking.category", "strict");
user_pref("privacy.partition.serviceWorkers", true);
user_pref(
  "privacy.partition.always_partition_third_party_non_cookie_storage",
  true);
user_pref(
  "privacy.partition.always_partition_third_party_non_cookie_storage"
    + ".exempt_sessionstorage",
  false);

// sanitize on shutdown
user_pref("privacy.sanitize.sanitizeOnShutdown", true);
user_pref("privacy.clearOnShutdown.cache", true);
user_pref("privacy.clearOnShutdown.downloads", true);
user_pref("privacy.clearOnShutdown.formdata", true);
user_pref("privacy.clearOnShutdown.offlineApps", true);
user_pref("privacy.clearOnShutdown.openWindows", true);
user_pref("privacy.clearOnShutdown_v2.cache", true);
user_pref("privacy.clearOnShutdown_v2.historyFormDataAndDownloads", true);
user_pref("privacy.clearsitedata.cache.enabled", true);
user_pref("browser.helperApps.deleteTempFileOnExit", true);

// data to clear when nuking
user_pref("privacy.sanitize.timeSpan", 0);
user_pref("privacy.cpd.cache", true);
user_pref("privacy.cpd.formdata", true);
user_pref("privacy.cpd.history", true);
user_pref("privacy.cpd.sessions", true);
user_pref("privacy.cpd.offlineApps", false);
user_pref("privacy.cpd.cookies", false);
user_pref("privacy.cpd.downloads", true);
user_pref("privacy.cpd.openWindows", false);
user_pref("privacy.cpd.passwords", false);
user_pref("privacy.cpd.siteSettings", false);

// miscellaneous
user_pref("middlemouse.contentLoadURL", false);
user_pref("network.IDN_show_punycode", true);
user_pref("browser.download.manager.addToRecentDocs", false);

// disable recommended extensions/features
user_pref(
  "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons",
  false);
user_pref(
  "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features",
  false);

// ----------------------------------------------------------------------------
// OPTIMIZATION
// trying to force firefox to actually use hardware
// ----------------------------------------------------------------------------

user_pref("webgl.disabled", false);
user_pref("webgl.enable-webgl2", true);
user_pref("webgl.force-enabled", true);
user_pref("gfx.webrender.all", true);
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("media.hardware-video-decoding.force-enabled", true);
