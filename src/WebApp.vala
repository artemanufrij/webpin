public class WebApp : Gtk.Stack {

    public WebKit.WebView app_view;
    public WebKit.WebView external_view;
    public string ui_color = "none";
    private string app_url;
    private GLib.DesktopAppInfo info;
    private DesktopFile file;
    private WebKit.CookieManager cookie_manager;
    private Gtk.Box container; //the spinner container

    public signal void external_request ();
    public signal void theme_color_changed(string color);

    public WebApp (string webapp_name, string app_url) {

        this.app_url = app_url;
        set_transition_duration (1000);

        //configure cookies settings
        cookie_manager = WebKit.WebContext.get_default ().get_cookie_manager ();
        cookie_manager.set_accept_policy (WebKit.CookieAcceptPolicy.ALWAYS);

        string cookie_db = Environment.get_user_cache_dir () + "/webby/cookies/";

        var dir = GLib.File.new_for_path (cookie_db);

        if (!dir.query_exists (null)) {
            try {
                dir.make_directory_with_parents (null);
                GLib.debug ("Directory '%s' created", dir.get_path ());
            } catch (Error e) {
                GLib.error ("Could not create caching directory.");
            }
        }

        cookie_manager.set_persistent_storage (cookie_db + "cookies.db", WebKit.CookiePersistentStorage.SQLITE);

        //load app viewer
        app_view = new  WebKit.WebView.with_context (WebKit.WebContext.get_default ());
        app_view.load_uri (app_url);

        //create external viewer
        this.external_view = new WebKit.WebView ();

        //loading view
        var spinner = new Gtk.Spinner();
        spinner.active = true;
        spinner.halign = Gtk.Align.CENTER;
        spinner.valign = Gtk.Align.CENTER;
        spinner.set_size_request (24, 24);
        container = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        container.halign = Gtk.Align.FILL;
        container.valign = Gtk.Align.FILL;
        container.pack_start(spinner, true, true, 0);

        //overlay trick to make snapshot work even with the spinner
        var overlay = new Gtk.Overlay ();
        overlay.add(app_view);
        overlay.add_overlay(container);

        add_titled(overlay, "app", "app");
        add_titled(external_view, "external", "external");
        set_visible_child_name ("app");

        app_view.create.connect ( () => {
            print("external request");
            external_request ();
            return external_view;
        });
        external_view.create.connect ( () => {
            print("external request");
            set_visible_child_name ("external");
            return external_view;
        });

        info = DesktopFile.get_app_by_url(app_url);
        file = new DesktopFile.from_desktopappinfo(info);
        //load theme color saved in desktop file
        if (info != null && info.has_key("WebpinThemeColor")) {
            var color = info.get_string("WebpinThemeColor");
            print("COLOR: " + color+"\n");
            if(color != "none") {
                ui_color = color;
            }
        }


        Gdk.RGBA background = {};
        if (!background.parse (ui_color)){
            background = {1,1,1,1};
        }
        container.override_background_color (Gtk.StateFlags.NORMAL, background);

        //update theme color if changed
        app_view.load_changed.connect ( (load_event) => {
            if (load_event == WebKit.LoadEvent.FINISHED) {
                print("determine color");
                determine_theme_color.begin();
            } else {
                container.set_visible(true);
            }
        });
    }

  public DesktopFile get_desktop_file () {
    return this.file;
  }

	/**Taken from WebView.vala in lp:midori
	 * Check for the theme-color meta tag in the page and if that one can't be
	 * found grabs the color from the current page and uses the first 3 rows
	 * of pixels to get a good representative color of the page
	 */
	public async void determine_theme_color () {

        //FIXME: This is useless without JSCore
        /*string script = "var t = document.getElementsByTagName('meta').filter(function(e){return e.name == 'theme-color';)[0]; t ? t.value : null;";
		app_view.run_javascript.begin (script, null, (obj, res)=> {

        });*/

		var snap = (Cairo.ImageSurface) yield app_view.get_snapshot (WebKit.SnapshotRegion.VISIBLE,
			                                                         WebKit.SnapshotOptions.NONE, null);

		// data ist in BGRA apparently (according to testing). Docs said ARGB, but that
		// appears not to be the case
		unowned uint8[] data = snap.get_data ();
		uint8 r = data[2];
        uint8 g = data[1];
        uint8 b = data[0];

		for (var i = 4; i < snap.get_width () * 3 * 4; i += 4) {
			r = (r + data[i + 2]) / 2;
			g = (g + data[i + 1]) / 2;
			b = (b + data[i + 0]) / 2;
		}

		var color = "#%02x%02x%02x".printf (r, g, b);

        if (color != ui_color) {
            ui_color = color;
            Gdk.RGBA background = {};
            background.parse (ui_color);
            container.override_background_color (Gtk.StateFlags.NORMAL, background);
            theme_color_changed(ui_color);
            if (file != null)
                file.edit_propertie ("WebpinThemeColor", ui_color);
        }
        container.set_visible(false);
	}
}
