public class WebBar : Gtk.HeaderBar {


    public enum title_mode {
        TITLE,
        BROWSER;
    }

    UrlEntry url_entry;
    Gtk.Button share_button;
    Gtk.Button back_button;
    WebKit.WebView webview;

    public signal void back_event();

    public WebBar (WebKit.WebView webview) {

        this.get_style_context ().remove_class ("header-bar");
        this.webview = webview;

        url_entry = new UrlEntry();
        url_entry.show_all();

        share_button = new Gtk.Button.from_icon_name ("application-menu-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        share_button.margin_left = 15;
        share_button.show_all ();

        back_button = new Gtk.Button.from_icon_name ("go-next-symbolic-rtl", Gtk.IconSize.SMALL_TOOLBAR);
        back_button.margin_right = 15;
        back_button.show_all ();

        pack_start (back_button);
        pack_start (url_entry);
        pack_end (share_button);

        custom_title = new Gtk.Label(null);
        connect_signals ();
        show();
    }


   private void connect_signals () {
        webview.load_changed.connect ( (event) => {
            if (event == WebKit.LoadEvent.STARTED)
                url_entry.set_text (webview.uri);
        });

        back_button.clicked.connect( () => { back_event(); });
        back_button.activate.connect( () => { back_event(); });
    }

    public void set_title_mode (title_mode mode) {

        if (mode == title_mode.TITLE) {
            custom_title = null;
            remove (share_button);
            remove (back_button);
            remove (url_entry);
            this.get_style_context ().remove_class ("header-bar");
        } else {
            pack_start (back_button);
            pack_start (url_entry);
            pack_end (share_button);
            custom_title = new Gtk.Label(null);
            this.get_style_context ().add_class ("header-bar");
        }
    }


}
