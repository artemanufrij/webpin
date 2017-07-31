public class DesktopFile : GLib.Object {

    private string template = """
                                [Desktop Entry]
                                Version=1.0
                                Name=Webby
                                GenericName=Web app
                                Comment=Webby web app
                                Exec=webby
                                Keywords=webby;webapp;internet;
                                Icon=application-default-icon
                                Terminal=false
                                Type=Application
                                Categories=Network;
                                X-GNOME-FullName=Webby
                                StartupWMClass=Webby
                                WebbyThemeColor=none""";


    private GLib.KeyFile file;

    public string name { get; private set; }
    public string url { get; private set; }
    public string icon { get; private set; }

    public DesktopFile (string name, string url, string icon) {
        this.name = name;
        this.url = url;
        this.icon = icon;

        file = new GLib.KeyFile();
        file.load_from_data (template, -1, GLib.KeyFileFlags.NONE);
        //TODO: Category
        file.set_string ("Desktop Entry", "Name", name);
        file.set_string ("Desktop Entry", "GenericName", name);
        file.set_string ("Desktop Entry", "X-GNOME-FullName", name);
        file.set_string ("Desktop Entry", "Exec", "webby " + url);
        file.set_string ("Desktop Entry", "Icon", icon);
        file.set_string ("Desktop Entry", "StartupWMClass", url);
    }

    public DesktopFile.from_desktopappinfo(GLib.DesktopAppInfo info) {
        file = new GLib.KeyFile();
        file.load_from_file (info.filename, KeyFileFlags.NONE);
        this.name = info.get_display_name ();
        this.icon = info.get_icon ().to_string ();
        this.url = file.get_string ("Desktop Entry", "Exec").substring (6);
    }

    public bool edit_propertie (string propertie, string val) {
        string filename = GLib.Environment.get_user_data_dir () + "/applications/" +file.get_string("Desktop Entry", "Name") + "-webby.desktop";
        file = new GLib.KeyFile();
        file.load_from_file (filename, KeyFileFlags.NONE);
        file.set_string ("Desktop Entry", propertie, val);
        return file.save_to_file (filename);
    }

    public GLib.DesktopAppInfo save_to_file () {
        string filename = GLib.Environment.get_user_data_dir () + "/applications/" +file.get_string("Desktop Entry", "Name") + "-webby.desktop";
        print("Desktop file created: " + filename);
        file.save_to_file (filename);
        return new GLib.DesktopAppInfo.from_filename (filename);
    }

    public bool delete_file () {
        string filename = GLib.Environment.get_user_data_dir () + "/applications/" +file.get_string("Desktop Entry", "Name") + "-webby.desktop";
	    File file = File.new_for_path (filename);
	    try {
		    file.delete ();
	    } catch (Error e) {
            print(e.message + "\n");
            return false;
	    }
        return true;
    }

    public static Gee.HashMap<string, GLib.DesktopAppInfo> get_webby_applications () {

        var list = new Gee.HashMap<string, GLib.DesktopAppInfo>();

        foreach (GLib.AppInfo app in GLib.AppInfo.get_all()) {

            var desktop_app = new GLib.DesktopAppInfo(app.get_id ());

            //FIXME: This is not working, vala problem?
            //var keywords = desktop_app.get_keywords ();

            string keywords = desktop_app.get_string ("Keywords");

            if (keywords != null && keywords.contains ("webby")) {
                list.set(desktop_app.get_name(), desktop_app);
            }
        }
        return list;
    }

    public static GLib.DesktopAppInfo? get_app_by_url (string url) {
        foreach (GLib.AppInfo app in GLib.AppInfo.get_all()) {

            var desktop_app = new GLib.DesktopAppInfo(app.get_id ());

            var exec = desktop_app.get_string ("Exec");

            if (exec != null && exec.contains (url)) {
                return desktop_app;
            }
        }
        return null;
    }

    public static Gee.HashMap<string, GLib.AppInfo> get_applications() {

        var list = new Gee.HashMap<string, GLib.AppInfo>();

        foreach (GLib.AppInfo app in GLib.AppInfo.get_all()) {
            list.set(app.get_name(), app);
        }

        return list;
    }
}
