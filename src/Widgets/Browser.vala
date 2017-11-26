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

namespace Webpin.Widgets {
    public class Browser : Gtk.Stack {
        public WebKit.WebView app_view { get; private set; }
        public DesktopFile desktop_file { get; private set; }

        WebKit.CookieManager cookie_manager;
        Gtk.Box container;
        Granite.Widgets.Toast app_notification;
        GLib.Icon icon_for_notification;

        public signal void external_request (WebKit.NavigationAction action);
        public signal void request_begin ();
        public signal void request_finished ();
        public signal void desktop_notification (string title, string body, GLib.Icon icon);
        public signal void found_website_color (Gdk.RGBA color);


        public Browser (DesktopFile desktop_file) {
            this.desktop_file = desktop_file;
            this.transition_duration = 350;
            this.transition_type = Gtk.StackTransitionType.SLIDE_UP;

            string cookie_db = Environment.get_user_cache_dir () + "/webpin/cookies/";
            var dir = GLib.File.new_for_path (cookie_db);
            if (!dir.query_exists (null)) {
                try {
                    dir.make_directory_with_parents (null);
                } catch (Error err) {
                    warning ("Could not create caching directory.");
                }
            }

            cookie_manager = WebKit.WebContext.get_default ().get_cookie_manager ();
            cookie_manager.set_accept_policy (WebKit.CookieAcceptPolicy.ALWAYS);
            cookie_manager.set_persistent_storage (cookie_db + "cookies.db", WebKit.CookiePersistentStorage.SQLITE);

            app_view = new WebKit.WebView.with_context (WebKit.WebContext.get_default ());
            app_view.load_uri (desktop_file.url);

            container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            app_notification = new Granite.Widgets.Toast ("");

            var overlay = new Gtk.Overlay ();
            overlay.add (app_view);
            overlay.add_overlay (app_notification);

            this.add_named (container, "splash");
            this.add_named (overlay, "app");

            var icon_file = File.new_for_path (desktop_file.icon);

            Gtk.Image icon;
            if (icon_file.query_exists ()) {
                try {
                    icon = new Gtk.Image.from_pixbuf (new Gdk.Pixbuf.from_file_at_scale (desktop_file.icon, 48, 48, true));
                    icon_for_notification = GLib.Icon.new_for_string (desktop_file.icon);
                } catch (Error err) {
                    warning (err.message);
                    icon = new Gtk.Image.from_icon_name ("com.github.artemanufrij.webpin", Gtk.IconSize.DIALOG);
                }
            } else {
                icon = new Gtk.Image.from_icon_name (desktop_file.icon, Gtk.IconSize.DIALOG);
                icon_for_notification = new GLib.ThemedIcon (desktop_file.icon);
            }
            container.pack_start (icon, true, true, 0);

            app_view.create.connect ((action) => {
                app_notification.title = _("Open request in an external application…");
                app_notification.send_notification ();

                external_request (action);
                return new WebKit.WebView ();
            });

            app_view.load_changed.connect ((load_event) => {
                request_begin ();
                if (load_event == WebKit.LoadEvent.FINISHED) {
                    visible_child_name = "app";
                    if (app_notification.reveal_child) {
                        app_notification.reveal_child = false;
                    }
                    request_finished ();
                    var source = app_view.get_main_resource ();
                    source.get_data.begin (null, (obj, res) => {
                        try {
                            var body = (string)source.get_data.end (res);
                            var regex = new Regex ("(?<=<meta name=\"theme-color\" content=\")#[0-9a-fA-F]{6}");
                            MatchInfo match_info;
                            if (regex.match (body, 0, out match_info)) {
                                var result = match_info.fetch (0);
                                Gdk.RGBA return_value = {0, 0, 0, 1};
                                if (return_value.parse (result)) {
                                    found_website_color (return_value);
                                }
                            }
                        } catch (Error err) {
                            warning (err.message);
                        }
                    });
                }
            });

            app_view.show_notification.connect ((notification) => {
                desktop_notification (notification.title, notification.body, icon_for_notification);
                return true;
            });

            app_view.permission_request.connect ((permission) => {
                var permission_type = permission as WebKit.NotificationPermissionRequest;
                if (permission_type != null) {
                    permission_type.allow ();
                }
                return false;
            });
        }
    }
}
