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
        Gtk.Box app_container;
        Granite.Widgets.Toast app_notification;
        GLib.Icon icon_for_notification;
        Gtk.InfoBar download_info_bar;
        
        private ulong app_notification_listener_handle;
        
        // To save downloaded files:
        private string tmp_dir;
        private ulong info_bar_signal_handle;

        public signal void external_request (WebKit.NavigationAction action);
        public signal void request_begin ();
        public signal void request_finished ();
        public signal void desktop_notification (string title, string body, GLib.Icon icon);
        public signal void found_website_color (Gdk.RGBA color);


        public Browser (DesktopFile desktop_file) {
            this.tmp_dir = DirUtils.make_tmp(".XXXXXX");
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

            app_container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
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
            app_container.pack_start(overlay, true, true, 0);

            this.add_named (container, "splash");
            this.add_named (app_container, "app");

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
            
            //type_info<WebKit.WebView>();
            web_view.get_context().download_started.connect((download) => {
                download.decide_destination.connect((suggested_filename) => {
                    download.set_destination("file://" + tmp_dir + "/" + suggested_filename);
                    download.finished.connect(() => {
                        process_download(download, suggested_filename, tmp_dir + "/" + suggested_filename);
                    });
                    return true;
                });
            });
            
            download_info_bar = new Gtk.InfoBar();
            download_info_bar.add_button(_("Open"), 1);
            download_info_bar.add_button(_("Save"), 2);
            download_info_bar.set_show_close_button(true);
            download_info_bar.set_message_type (Gtk.MessageType.OTHER);
            download_info_bar.set_revealed(false);
            
            download_info_bar.close.connect(() => {
                //container.remove(download_info_bar);
                download_info_bar.set_no_show_all(true);
                download_info_bar.set_revealed(false);
                download_info_bar.hide();
            });
            
            app_container.pack_end(download_info_bar, false, false, 0);
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
        
        private void process_download(WebKit.Download download, string suggested_filename, string downloaded_path) {
            if (info_bar_signal_handle != 0)
                download_info_bar.disconnect(info_bar_signal_handle);
            download_info_bar.set_no_show_all(false);
            download_info_bar.show_all();
            print("suggested filename for download: " + suggested_filename);

            var content_area = download_info_bar.get_content_area ();
            var old_children = content_area.get_children ();
            foreach (Gtk.Widget w in old_children) {
                content_area.remove (w);
            }
            content_area.add(new Gtk.Label(_("»%s« has been downloaded.").replace("%s", suggested_filename)));
            
            info_bar_signal_handle = download_info_bar.response.connect((response) => {
                var downloaded_file = File.new_for_path (downloaded_path);
            
                if (response == 1) { // Open file
                    try {
                        AppInfo.launch_default_for_uri (downloaded_file.get_uri (), null);
                        download_info_bar.set_no_show_all(true);
                        download_info_bar.set_revealed(false);
                        download_info_bar.hide();
                    } catch {
                        show_notification(_ ("No fitting application could be found."));
                    }
                } else { // save file
                    move_downloaded_file(downloaded_file, suggested_filename);
                    download_info_bar.set_no_show_all(true);
                    download_info_bar.set_revealed(false);
                    download_info_bar.hide();
                }
            });
            
            download_info_bar.set_revealed(true);
            download_info_bar.show_all();
        }
        
        string uri; // quick fix for referencing in callback function below
        private void move_downloaded_file(File downloaded_file, string suggested_filename) {
            var home = GLib.Environment.get_home_dir();
            var download_dir = home + "/Downloads";
            
            if (!FileUtils.test(download_dir, GLib.FileTest.IS_DIR)) {
                DirUtils.create(download_dir, 0666);
            }
            
            var dest = get_download_location(File.new_for_path(home + "/Downloads/" + suggested_filename));
        
            try {
                downloaded_file.move(dest, FileCopyFlags.NONE, null);
                uri = dest.get_uri ();
                show_notification(_("File has been saved to »%s«").replace("%s", dest.get_path()), _("Open"), () => {
                    print("uri2: " + uri);
                    try {
                        AppInfo.launch_default_for_uri (uri, null);
                    } catch {
                        show_notification(_ ("No fitting application could be found."));
                    }
                });
            } catch (Error e) {
                show_notification(_("The downloaded file could not be saved to your download directory. You can access it directly under »%s«").replace("%s", downloaded_file.get_path()));
                stdout.printf("Error while moving downloaded file: %s\n", e.message);
            }
        }
        
        delegate void VoidFunc();
        private void show_notification(string message, string action = "", VoidFunc on_action = null) {
            if (app_notification_listener_handle != 0)
                app_notification.disconnect(app_notification_listener_handle);
            app_notification.title = message;
            if (action == "")
                app_notification.set_default_action(null);
            else
                app_notification.set_default_action(action);
            if (on_action != null)
                app_notification_listener_handle = app_notification.default_action.connect(on_action);
            else
                app_notification_listener_handle = 0;
            app_notification.send_notification ();
        }
        
        private File get_download_location(File dest) {
            var res = dest;
            var counter = 1;
            while (res.query_exists()) {
                var name = dest.get_basename();
                var index = name.last_index_of(".");
                if (index > 0) {
                    name = name.substring(0, index) + " (" + (++counter).to_string() + ")" + name.substring(index);
                } else {  // filename starts with dot or does not have an extension
                    name = name + " (" + (++counter).to_string() + ")";
                }
                res = File.new_for_path(dest.get_parent().get_path() + "/" + name);
                print(dest.get_path());
            }
            return res;
        }
    }
}

public void type_info<T>() {
var type = typeof(T);
TypeQuery query;
type.query(out query);
stdout.printf("%s %c%c%c%C%C%C%C%C%C%C%C size(class = %u instance = %u)\n", type.name(),
type.is_object() ? 'o' : '-',
type.is_abstract() ? 'a' : '-',
type.is_classed() ? 'c' : '-',
type.is_derivable() ? (type.is_deep_derivable() ? 'D' : 'd') : '-',
type.is_derived() ? 'v' : '-',
type.is_fundamental() ? 'F' : '-',
type.is_instantiatable() ? 'N' : '-',
type.is_interface() ? 'i' : '-',
type.is_value_type() ? 's' : '-',
type.is_enum() ? 'e' : '-',
type.is_flags() ? 'f' : '-',
query.class_size,
query.instance_size);

if (type.is_object()) {
stdout.printf("class %s", type.name());
for(var parent = type.parent(); parent != Type.INVALID; parent = parent.parent()) {
stdout.printf(" : %s", parent.name());
}
stdout.printf(" {\n");
foreach (var property in ((ObjectClass)type.class_ref()).list_properties()) {
stdout.printf("\t%s :: %s -- %s\n", property.name, property.value_type.name(), property.get_blurb());
}
stdout.printf("}\n");
}
}
