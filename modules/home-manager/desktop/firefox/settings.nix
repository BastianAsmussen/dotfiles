{
  # Quality of life stuff.
  "browser.aboutConfig.showWarning" = false;
  "browser.tabs.firefox-view" = false;
  "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
  "toolkit.zoomManager.zoomValues" = ".8,.90,.95,1,1.1,1.2";
  "xpinstall.signatures.required" = false;
  "browser.uidensity" = 1;
  "extensions.autoDisableScopes" = 0; # Auto-enable extensions.
  "general.autoScroll" = true; # Enable autoscrolling.
  "browser.startup.homepage" = "";

  # Prevent EULA dialog to popup on first run.
  "browser.EULA.override" = true;

  # Enable DRM.
  "browser.eme.ui.enabled" = true;
  "media.eme.ui.enabled" = true;

  # Only allow HTTPS in all windows, including private browsing
  "dom.security.https_only_mode" = true;

  # Telemetry.
  "browser.newtabpage.activity-stream.feeds.telemetry" = false;
  "browser.ping-centre.telemetry" = false;
  "browser.tabs.crashReporting.sendReport" = false;
  "devtools.onboarding.telemetry.logged" = false;
  "toolkit.telemetry.enabled" = false;
  "toolkit.telemetry.server" = "data:,";
  "toolkit.telemetry.unified" = false;
  "toolkit.telemetry.archive.enabled" = false;
  "toolkit.telemetry.newProfilePing.enabled" = false;
  "toolkit.telemetry.shutdownPingSender.enabled" = false;
  "toolkit.telemetry.bhrPing.enabled" = false;
  "toolkit.telemetry.firstShutdownPing.enabled" = false;
  "extensions.webcompat-reporter.enabled" = false;
  "datareporting.policy.dataSubmissionEnabled" = false;
  "datareporting.healthreport.uploadEnabled" = false;
  "browser.urlbar.eventTelemetry.enabled" = false;

  # Prevent websites from storing session data like cookies and forms.
  "browser.formfill.enable" = false;
  "browser.sessionstore.privacy_level" = 2;

  # Isolate cookies, you don't have to delete them every time, duh.
  "privacy.firstparty.isolate" = true;

  # Query stripping.
  "privacy.query_stripping.strip_list" = "__hsfp __hssc __hstc __s _hsenc _openstat dclid fbclid gbraid gclid hsCtaTracking igshid mc_eid ml_subscriber ml_subscriber_hash msclkid oft_c oft_ck oft_d oft_id oft_ids oft_k oft_lk oft_sk oly_anon_id oly_enc_id rb_clickid s_cid twclid vero_conv vero_id wbraid wickedid yclid";

  # Release notes and vendor URLs.
  "app.releaseNotesURL" = "http://127.0.0.1/";
  "app.vendorURL" = "http://127.0.0.1/";
  "app.privacyURL" = "http://127.0.0.1/";

  # Disable plugin installer.
  "plugins.hide_infobar_for_missing_plugin" = true;
  "plugins.hide_infobar_for_outdated_plugin" = true;
  "plugins.notifyMissingFlash" = false;

  # Speeding it up.
  "network.http.pipelining" = true;
  "network.http.proxy.pipelining" = true;
  "network.http.pipelining.maxrequests" = 10;
  "nglayout.initialpaint.delay" = 0;
  "nglayout.initialpaint.delay_in_oopif" = 0;
  "browser.startup.preXulSkeletonUI" = false;
  "content.notify.interval" = 100000;

  # Disable homecalling.
  "app.update.url" = "http://127.0.0.1/";
  "startup.homepage_welcome_url" = "";
  "browser.startup.homepage_override.mstone" = "ignore";

  # Don't call home for blacklisting.
  "extensions.blocklist.enabled" = false;

  # Disable help URLs.
  "app.support.baseURL" = "http://127.0.0.1/";
  "app.support.inputURL" = "http://127.0.0.1/";
  "app.feedback.baseURL" = "http://127.0.0.1/";
  "browser.uitour.url" = "http://127.0.0.1/";
  "browser.uitour.themeOrigin" = "http://127.0.0.1/";
  "plugins.update.url" = "http://127.0.0.1/";
  "browser.customizemode.tip0.learnMoreUrl" = "http://127.0.0.1/";

  # Privacy.
  "privacy.donottrackheader.enabled" = true;
  "privacy.trackingprotection.enabled" = true;
  "privacy.trackingprotection.socialtracking.enabled" = true;

  # Disable pinging URIs specified in HTML <a> ping= attributes.
  "browser.send_pings" = false;
  "app.normandy.enabled" = false;
  "app.shield.optoutstudies.enabled" = false;
  "javascript.use_us_english_locale" = true;
  "intl.accept_languages" = "en-US, en";

  "browser.translation.engine" = "";
  "media.gmp-provider.enabled" = false;
  "browser.urlbar.update2.engineAliasRefresh" = true;
  "browser.urlbar.suggest.engines" = false;
  "browser.urlbar.suggest.topsites" = false;
  "browser.urlbar.trending.featureGate" = false;
  "browser.urlbar.mdn.featureGate" = false;
  "browser.urlbar.weather.featureGate" = false;
  "browser.shopping.experience2023.enabled" = false;
  "security.OCSP.enabled" = 0;
  "security.OCSP.require" = false;
  "browser.discovery.containers.enabled" = false;
  "browser.discovery.enabled" = false;
  "browser.discovery.sites" = "http://127.0.0.1/";
  "services.sync.prefs.sync.browser.startup.homepage" = false;
  "browser.contentblocking.report.monitor.home_page_url" = "http://127.0.0.1/";
  "browser.contentblocking.category" = "strict";
  "dom.ipc.plugins.flash.subprocess.crashreporter.enabled" = false;
  "browser.safebrowsing.enabled" = false;
  "browser.safebrowsing.downloads.remote.enabled" = false;
  "browser.safebrowsing.malware.enabled" = false;
  "browser.safebrowsing.provider.google.updateURL" = "";
  "browser.safebrowsing.provider.google.gethashURL" = "";
  "browser.safebrowsing.provider.google4.updateURL" = "";
  "browser.safebrowsing.provider.google4.gethashURL" = "";
  "browser.safebrowsing.provider.mozilla.gethashURL" = "";
  "browser.safebrowsing.provider.mozilla.updateURL" = "";
  "services.sync.privacyURL" = "http://127.0.0.1/";
  "social.enabled" = false;
  "social.remote-install.enabled" = false;
  "datareporting.healthreport.about.reportUrl" = "http://127.0.0.1/";
  "datareporting.healthreport.service.enabled" = false;
  "datareporting.healthreport.documentServerURI" = "http://127.0.0.1/";
  "healthreport.uploadEnabled" = false;
  "social.toast-notifications.enabled" = false;
  "browser.slowStartup.notificationDisabled" = true;
  "network.http.sendRefererHeader" = 2;
  "network.http.referer.spoofSource" = true;

  # Disable "beacon" asynchronous HTTP transfers (used for analytics).
  "beacon.enabled" = false;

  # Disable sites taking over copy/paste.
  "dom.event.clipboardevents.enabled" = false;

  # Disable gamepad API to prevent USB device enumeration.
  "dom.gamepad.enabled" = false;

  # Prevent mouse middle click on new tab button to trigger searches or page loads.
  "browser.tabs.searchclipboardfor.middleclick" = false;

  # APS.
  "privacy.partition.always_partition_third_party_non_cookie_storage" = true;
  "privacy.partition.always_partition_third_party_non_cookie_storage.exempt_sessionstorage" = false;

  "privacy.userContext.enabled" = true;
  "privacy.userContext.ui.enabled" = true;

  "devtools.debugger.remote-enabled" = false;
  "devtools.selfxss.count" = 0;

  "webchannel.allowObject.urlWhitelist" = "";

  # We don't want to send the Origin header.
  "network.http.originextension" = false;
  "network.user_prefetch-next" = false;
  "network.dns.disablePrefetch" = true;
  "network.prefetch-next" = false;
  "network.predictor.enabled" = false;
  "network.http.sendSecureXSiteReferrer" = false;
  "app.normandy.api_url" = "";
  "experiments.manifest.uri" = "";

  "breakpad.reportURL" = "";

  # Make sure updater telemetry is disabled (https://trac.torproject.org/25909).
  "toolkit.telemetry.updatePing.enabled" = false;

  # Don't tell what plugins we have enabled (https://mail.mozilla.org/pipermail/firefox-dev/2013-November/001186.html).
  "plugins.enumerable_names" = "";
  "plugin.state.flash" = 0;
  "browser.search.update" = false;

  # Block HTTP authentication credential dialogs.
  "network.auth.subresource-http-auth-allow" = 1;
  "network.http.referer.XOriginTrimmingPolicy" = 2;

  # Disable GIO as it could bypass proxy.
  "network.gio.supported-protocols" = "";

  # Hidden, disable using uniform naming convention to prevent proxy bypass.
  "network.file.disable_unc_paths" = true;

  # Force WebRTC inside proxy when one is used.
  "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;

  # forces dns query through the proxy when using one
  "network.proxy.socks_remote_dns" = true;

  # Disable sensors
  "dom.battery.enabled" = false;
  "device.sensors.enabled" = false;
  "camera.control.face_detection.enabled" = false;
  "camera.control.autofocus_moving_callback.enabled" = false;
  "network.http.speculative-parallel-limit" = 0;
  "browser.urlbar.speculativeConnect.enabled" = false;

  # No search suggestions.
  "browser.urlbar.userMadeSearchSuggestionsChoice" = true;
  "browser.search.suggest.enabled" = false;

  # Always ask before restoring the browsing session.
  "browser.sessionstore.max_resumed_crashes" = 0;

  # Don't ping Mozilla for MitM detection (https://bugs.torproject.org/32321).
  "security.certerrors.mitm.priming.enabled" = false;
  "security.certerrors.recordEventTelemetry" = false;

  # Disable shield/heartbeat.
  "extensions.shield-recipe-client.enabled" = false;
  "browser.selfsupport.url" = "";

  # Don't download ads for the newtab page.
  "browser.newtabpage.directory.source" = "";
  "browser.newtabpage.directory.ping" = "";
  "browser.newtabpage.introShown" = true;

  # Disable geolocation.
  "geo.enabled" = false;
  "geo.wifi.uri" = "";
  "browser.search.geoip.url" = "";
  "browser.search.geoSpecificDefaults" = false;
  "browser.search.geoSpecificDefaults.url" = "";
  "browser.search.modernConfig" = false;

  # Disable captive portal detection.
  "captivedetect.canonicalURL" = "";
  "network.captive-portal-service.enabled" = false;

  # Canvas fingerprint protection.
  "privacy.resistFingerprinting" = true;
  "privacy.trackingprotection.cryptomining.enabled" = true;

  # Prevents rfp from breaking AMO.
  "privacy.resistFingerprinting.block_mozAddonManager" = true;
  "privacy.trackingprotection.fingerprinting.enabled" = true;

  # Services.
  "gecko.handlerService.schemes.mailto.0.name" = "";
  "gecko.handlerService.schemes.mailto.1.name" = "";
  "handlerService.schemes.mailto.1.uriTemplate" = "";
  "gecko.handlerService.schemes.mailto.0.uriTemplate" = "";
  "browser.contentHandlers.types.0.title" = "";
  "browser.contentHandlers.types.0.uri" = "";
  "browser.contentHandlers.types.1.title" = "";
  "browser.contentHandlers.types.1.uri" = "";
  "gecko.handlerService.schemes.webcal.0.name" = "";
  "gecko.handlerService.schemes.webcal.0.uriTemplate" = "";
  "gecko.handlerService.schemes.irc.0.name" = "";
  "gecko.handlerService.schemes.irc.0.uriTemplate" = "";

  "font.default.x-western" = "sans-serif";

  "extensions.getAddons.langpacks.url" = "http://127.0.0.1/";
  "lightweightThemes.getMoreURL" = "http://127.0.0.1/";
  "browser.geolocation.warning.infoURL" = "";
  "browser.xr.warning.infoURL" = "";

  # Mobile.
  "privacy.announcements.enabled" = false;
  "browser.snippets.enabled" = false;
  "browser.snippets.syncPromo.enabled" = false;
  "identity.mobilepromo.android" = "http://127.0.0.1/";
  "browser.snippets.geoUrl" = "http://127.0.0.1/";
  "browser.snippets.updateUrl" = "http://127.0.0.1/";
  "browser.snippets.statsUrl" = "http://127.0.0.1/";
  "datareporting.policy.firstRunTime" = 0;
  "datareporting.policy.dataSubmissionPolicyVersion" = 2;
  "browser.webapps.checkForUpdates" = 0;
  "browser.webapps.updateCheckUrl" = "http://127.0.0.1/";
  "app.faqURL" = "http://127.0.0.1/";

  # PFS URL.
  "pfs.datasource.url" = "http://127.0.0.1/";
  "pfs.filehint.url" = "http://127.0.0.1/";

  # Disable Link to FireFox Marketplace, currently loaded with non-free "apps".
  "browser.apps.URL" = "";

  # Disable Firefox Hello.
  "loop.enabled" = false;

  # Use old style user_preferences, that allow JavaScript to be disabled.
  "browser.user_preferences.inContent" = false;

  # Disable home snippets.
  "browser.aboutHomeSnippets.updateUrl" = "data:text/html";

  # In <about:user_preferences>, hide "More from Mozilla".
  "browser.user_preferences.moreFromMozilla" = false;

  # Disable SSDP.
  "browser.casting.enabled" = false;

  # Disable directory service.
  "social.directories" = "";

  # Don't report TLS errors to Mozilla.
  "security.ssl.errorReporting.enabled" = false;

  # Crypto hardening.
  "security.tls.unrestricted_rc4_fallback" = false;
  "security.tls.insecure_fallback_hosts.use_static_list" = false;
  "security.tls.version.min" = 3;
  "security.cert_pinning.enforcement_level" = 2;
  "security.remote_settings.crlite_filters.enabled" = true;
  "security.ssl.require_safe_negotiation" = true;
  "security.ssl.treat_unsafe_negotiation_as_broken" = true;
  "security.ssl3.rsa_seed_sha" = true;

  # Disable 0 RTT to improve TLS 1.3 security.
  "security.tls.enable_0rtt_data" = false;
  "security.tls.version.enable-deprecated" = false;
  "browser.xul.error_pages.expert_bad_cert" = true;

  # Force permission request to show real origin.
  "permissions.delegation.enabled" = true;

  # Revoke special permissions for some Mozilla domains.
  "permissions.manager.defaultsUrl" = "";

  # Avoid Logjam attack.
  "security.ssl3.dhe_rsa_aes_128_sha" = false;
  "security.ssl3.dhe_rsa_aes_256_sha" = false;
  "security.ssl3.dhe_dss_aes_128_sha" = false;
  "security.ssl3.dhe_rsa_des_ede3_sha" = false;
  "security.ssl3.rsa_des_ede3_sha" = false;

  # Disable Pocket integration.
  "browser.pocket.enabled" = false;
  "extensions.pocket.enabled" = false;

  # Disable "More from Mozilla".
  "browser.preferences.moreFromMozilla" = false;

  # Enable extensions by default in private mode.
  "extensions.allowPrivateBrowsingByDefault" = true;

  # Do not show unicode URLs (https://www.xudongz.com/blog/2017/idn-phishing/).
  "network.IDN_show_punycode" = true;

  # Disable screenshots extension.
  "extensions.screenshots.disabled" = true;

  # Disable onboarding.
  "browser.onboarding.newtour" = "performance,private,addons,customize,default";
  "browser.onboarding.updatetour" = "performance,library,singlesearch,customize";
  "browser.onboarding.enabled" = false;

  # New tab settings.
  "browser.newtabpage.activity-stream.showTopSites" = false;
  "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
  "browser.newtabpage.activity-stream.feeds.snippets" = false;
  "browser.newtabpage.activity-stream.disableSnippets" = true;
  "browser.newtabpage.activity-stream.tippyTop.service.endpoint" = "";

  # Enable xrender.
  "gfx.xrender.enabled" = true;

  # Disable push notifications.
  "dom.webnotifications.enabled" = false;
  "dom.webnotifications.serviceworker.enabled" = false;
  "dom.push.enabled" = false;

  # Disable recommended extensions.
  "browser.newtabpage.activity-stream.asrouter.useruser_prefs.cfr" = false;
  "extensions.htmlaboutaddons.discover.enabled" = false;
  "extensions.htmlaboutaddons.recommendations.enabled" = false;

  # Disable the settings server.
  "services.settings.server" = "";

  # Disable use of WiFi region/location information.
  "browser.region.network.scan" = false;
  "browser.region.network.url" = "";
  "browser.region.update.enabled" = false;

  # Disable VPN/mobile promotions.
  "browser.contentblocking.report.hide_vpn_banner" = true;
  "browser.contentblocking.report.mobile-ios.url" = "";
  "browser.contentblocking.report.mobile-android.url" = "";
  "browser.contentblocking.report.show_mobile_app" = false;
  "browser.contentblocking.report.vpn.enabled" = false;
  "browser.contentblocking.report.vpn.url" = "";
  "browser.contentblocking.report.vpn-promo.url" = "";
  "browser.contentblocking.report.vpn-android.url" = "";
  "browser.contentblocking.report.vpn-ios.url" = "";
  "browser.privatebrowsing.promoEnabled" = false;

  # Enable `@-moz-document` media query.
  "layout.css.moz-document.content.enabled" = true;

  # https://support.mozilla.org/en-US/kb/privacy-preserving-attribution
  "dom.private-attribution.submission.enabled" = false;

  # UI customizations.
  "browser.uiCustomization.state" = {
    placements = {
      widget-overflow-fixed-list = [];
      unified-extensions-area = [
        "sponsorblocker_ajay_app-browser-action"
        "_34daeb50-c2d2-4f14-886a-7160b24d66a4_-browser-action"
        "_74145f27-f039-47ce-a470-a662b129930a_-browser-action"
        "jid1-mnnxcxisbpnsxq_jetpack-browser-action"
        "skipredirect_sblask-browser-action"
        "dontfuckwithpaste_raim_ist-browser-action"
        "idcac-pub_guus_ninja-browser-action"
        "jid1-zadieub7xozojw_jetpack-browser-action"
        "_762f9885-5a13-4abd-9c77-433dcd38b8fd_-browser-action"
      ];

      nav-bar = [
        "back-button"
        "forward-button"
        "stop-reload-button"
        "customizableui-special-spring1"
        "urlbar-container"
        "customizableui-special-spring2"
        "downloads-button"
        "fxa-toolbar-menu-button"
        "ublock0_raymondhill_net-browser-action" # uBlock Origin.
        "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action" # Bitwarden.
        "addon_darkreader_org-browser-action" # Dark Reader.
        "unified-extensions-button"
      ];

      toolbar-menubar = ["menubar-items"];
      TabsToolbar = [
        "firefox-view-button"
        "tabbrowser-tabs"
        "new-tab-button"
        "alltabs-button"
      ];

      PersonalToolbar = ["personal-bookmarks"];
    };

    seen = [
      "dontfuckwithpaste_raim_ist-browser-action"
      "addon_darkreader_org-browser-action"
      "idcac-pub_guus_ninja-browser-action"
      "jid1-mnnxcxisbpnsxq_jetpack-browser-action"
      "jid1-zadieub7xozojw_jetpack-browser-action"
      "skipredirect_sblask-browser-action"
      "ublock0_raymondhill_net-browser-action"
      "_34daeb50-c2d2-4f14-886a-7160b24d66a4_-browser-action"
      "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"
      "_74145f27-f039-47ce-a470-a662b129930a_-browser-action"
      "_762f9885-5a13-4abd-9c77-433dcd38b8fd_-browser-action"
      "sponsorblocker_ajay_app-browser-action"
      "developer-button"
    ];

    dirtyAreaCache = [
      "unified-extensions-area"
      "nav-bar"
      "toolbar-menubar"
      "TabsToolbar"
      "PersonalToolbar"
    ];

    currentVersion = 20;
    newElementCount = 2;
  };
}
