static int main (string[] args) {

    Gtk.init (ref args);

    if (args.length < 2 || args[1] == "--about" || args[1] == "-d") {
        return AppWindow.instance.run (args);
    } else {
        var app_info = DesktopFile.get_app_by_url (args[1]);
        var app = new WebAppWindow(app_info.get_display_name (), args[1]);
        app.show_all ();
    }

    Gtk.main ();
    return 0;
}
