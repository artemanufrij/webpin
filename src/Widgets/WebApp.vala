/*-
 * Copyright (c) 2015 Erasmo Marín <erasmo.marin@gmail.com>
 * Copyright (c) 2017-2017 Artem Anufrij <artem.anufrij@live.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Artem Anufrij <artem.anufrij@live.de>
 */

namespace Webpin {
    public class WebApp : Gtk.Stack {

        public WebKit.WebView app_view;
        public string ui_color = "none";
        private string app_url;
        private GLib.DesktopAppInfo info;
        private DesktopFile file;
        private WebKit.CookieManager cookie_manager;
        private Gtk.Box container;
        Granite.Widgets.Toast app_notification;
        Notification desktop_notification;

        public signal void external_request (WebKit.NavigationAction action);
        public signal void theme_color_changed(string color);
        public signal void request_begin ();
        public signal void request_finished ();


        public WebApp (string webapp_name, string app_url) {

            this.app_url = app_url;

            //configure cookies settings
            cookie_manager = WebKit.WebContext.get_default ().get_cookie_manager ();
            cookie_manager.set_accept_policy (WebKit.CookieAcceptPolicy.ALWAYS);

            string cookie_db = Environment.get_user_cache_dir () + "/webpin/cookies/";

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
            app_view = new WebKit.WebView.with_context (WebKit.WebContext.get_default ());
            app_view.load_uri (app_url);

            container = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            container.halign = Gtk.Align.FILL;
            container.valign = Gtk.Align.FILL;

            app_notification = new Granite.Widgets.Toast ("");
            desktop_notification = new Notification ("");

            //overlay trick to make snapshot work even with the spinner
            var overlay = new Gtk.Overlay ();
            overlay.add (app_view);
            overlay.add_overlay (app_notification);

            add_named (container, "splash");
            add_named (overlay, "app");

            transition_duration = 350;
            transition_type = Gtk.StackTransitionType.SLIDE_UP;

            app_view.create.connect ((action) => {
                print("external request");
                app_notification.title = _("Open request in an external application…");
                app_notification.send_notification ();

                external_request (action);
                return new WebKit.WebView ();
            });

            info = DesktopFile.get_app_by_url(app_url);
            file = new DesktopFile.from_desktopappinfo(info);
            //load theme color saved in desktop file
            if (info != null && info.has_key("WebpinThemeColor")) {
                var color = info.get_string("WebpinThemeColor");
                debug("COLOR: " + color+"\n");
                if(color != "none") {
                    ui_color = color;
                }
            }

            var icon_file = File.new_for_path (file.icon);

            Gtk.Image icon;
            if (icon_file.query_exists ()) {
                try {
                    icon = new Gtk.Image.from_pixbuf (new Gdk.Pixbuf.from_file_at_scale (file.icon, 48, 48, true));

                } catch (Error e) {
                    warning (e.message);
                    icon = new Gtk.Image.from_icon_name ("artemanufrij.webpin", Gtk.IconSize.DIALOG);
                }
            } else {
                icon = new Gtk.Image.from_icon_name (file.icon, Gtk.IconSize.DIALOG);
            }
            container.pack_start(icon, true, true, 0);

            Gdk.RGBA background = {};
            if (!background.parse (ui_color)){
                background = {1,1,1,1};
            }
            container.override_background_color (Gtk.StateFlags.NORMAL, background);

            //update theme color if changed
            app_view.load_changed.connect ( (load_event) => {
                request_begin ();
                if (load_event == WebKit.LoadEvent.FINISHED) {
                    debug ("determine color");
                    determine_theme_color.begin();
                }
            });

            app_view.show_notification.connect ((notification) => {
                desktop_notification.set_title (notification.title);
                desktop_notification.set_body (notification.body);
                WebpinApp.instance.send_notification (null, desktop_notification);
                return false;
            });

            app_view.permission_request.connect ((permission) => {
                var permission_type = permission as WebKit.NotificationPermissionRequest;
                if (permission_type != null) {
                    permission_type.allow ();
                }
                return false;
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

            Cairo.ImageSurface snap = null;

            try {
                snap = (Cairo.ImageSurface) yield app_view.get_snapshot (WebKit.SnapshotRegion.VISIBLE, WebKit.SnapshotOptions.NONE, null);
            } catch (Error e) {
                warning (e.message);
            }

            if (snap != null) {
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

                if (color != ui_color && color != "#ffffff") {
                    ui_color = color;
                    Gdk.RGBA background = {};
                    background.parse (ui_color);
                    container.override_background_color (Gtk.StateFlags.NORMAL, background);
                    theme_color_changed(ui_color);
                    if (file != null)
                        file.edit_propertie ("WebpinThemeColor", ui_color);
                }
            }
            visible_child_name = "app";
            if (app_notification.reveal_child) {
                app_notification.reveal_child = false;
            }
            request_finished ();
	    }
    }
}
