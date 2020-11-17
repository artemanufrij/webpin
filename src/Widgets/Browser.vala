/*-
 * Copyright (c) 2015 Erasmo Marín <erasmo.marin@gmail.com>
 * Copyright (c) 2017-2018 Artem Anufrij <artem.anufrij@live.de>
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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
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
        public WebKit.WebView web_view { get; private set; }
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

            web_view = new WebKit.WebView.with_context (WebKit.WebContext.get_default ()) {
                settings = new WebKit.Settings () {
                    enable_back_forward_navigation_gestures = true,
                    enable_mediasource = true,
                    enable_webgl = true
                }
            };

            cookie_manager = web_view.web_context.get_cookie_manager ();
            cookie_manager.set_accept_policy (WebKit.CookieAcceptPolicy.ALWAYS);
            cookie_manager.set_persistent_storage (cookie_db + "cookies.db", WebKit.CookiePersistentStorage.SQLITE);

            web_view.load_uri (desktop_file.url);

            container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            if (desktop_file.color != null) {
                var css_provider = new Gtk.CssProvider();
                try {
                    css_provider.load_from_data (""" .box { background: """ + desktop_file.color.to_string () + """; } """);
                } catch (Error err) {
                    warning (err.message);
                }
                container.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                container.get_style_context ().add_class ("box");
            }

            app_notification = new Granite.Widgets.Toast ("");

            var overlay = new Gtk.Overlay ();
            overlay.add (web_view);
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

            web_view.create.connect ((action) => {
                app_notification.title = _ ("Open request in an external application…");
                app_notification.send_notification ();

                external_request (action);
                return new WebKit.WebView ();
            });

            web_view.load_changed.connect ((load_event) => {
                request_begin ();
                if (load_event == WebKit.LoadEvent.FINISHED) {
                    visible_child_name = "app";
                    if (app_notification.reveal_child) {
                        app_notification.reveal_child = false;
                    }
                    request_finished ();
                }
            });

            web_view.show_notification.connect ((notification) => {
                desktop_notification (notification.title, notification.body, icon_for_notification);
                return true;
            });

            web_view.permission_request.connect ((permission) => {
                var permission_type = permission as WebKit.NotificationPermissionRequest;
                if (permission_type != null) {
                    permission_type.allow ();
                }
                return false;
            });

            web_view.button_press_event.connect ((event) => {
                if (event.button == 8) {
                    web_view.go_back ();
                    return true;
                } else if (event.button == 9) {
                    web_view.go_forward ();
                    return true;
                }
                return base.button_press_event (event);
            });

            web_view.key_press_event.connect ((event) => {
                if (event.keyval == Gdk.Key.Back) {
                    web_view.go_back ();
                    return true;
                } else if (event.keyval == Gdk.Key.Forward) {
                    web_view.go_forward ();
                    return true;
                }
                return base.key_press_event (event);
            });
        }

        public void go_home () {
            web_view.load_uri (desktop_file.url);
            request_finished ();
        }

        public void go_back () {
            web_view.go_back ();
            request_finished ();
        }

        public void go_forward () {
            web_view.go_forward ();
            request_finished ();
        }

        public bool can_go_back () {
            return web_view.can_go_back ();
        }

        public bool can_go_forward () {
            return web_view.can_go_forward ();
        }

        public void reload () {
            web_view.reload ();
        }

        public void reload_bypass_cache () {
            web_view.reload_bypass_cache ();
        }
    }
}
