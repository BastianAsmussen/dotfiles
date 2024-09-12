{lib, ...}: {
  dconf.settings = {
    "org/gnome/desktop/interface".show-battery-percentage = true;
    "org/gnome/desktop/peripherals/touchpad" = {
      tap-to-click = true;
      two-finger-scrolling-enabled = true;
    };

    "org/gnome/desktop/search-providers" = {
      disabled = ["org.gnome.Boxes.desktop"];
      enabled = ["org.gnome.Weather.desktop"];
      sort-order = [
        "org.gnome.Contacts.desktop"
        "org.gnome.Documents.desktop"
        "org.gnome.Nautilus.desktop"
        "org.gnome.Calendar.desktop"
        "org.gnome.Calculator.desktop"
        "org.gnome.Software.desktop"
        "org.gnome.Settings.desktop"
        "org.gnome.clocks.desktop"
        "org.gnome.design.IconLibrary.desktop"
        "org.gnome.seahorse.Application.desktop"
        "org.gnome.Weather.desktop"
        "org.gnome.Boxes.desktop"
      ];
    };

    "org/gnome/settings-daemon/plugins/power" = {
      idle-dim = false;
      power-button-action = "interactive";
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "nothing";
    };

    "org/gnome/desktop/session".idle-delay = lib.hm.gvariant.mkUint32 0;
    "org/gnome/TextEditor".keybindings = "vim";
    "org/gnome/shell/app-switcher".current-workspace-only = false;
  };
}
