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
    public class DesktopFile : GLib.Object {

        private string template = """
                                    [Desktop Entry]
                                    Name=Webpin
                                    GenericName=Web app
                                    Comment=Webpin web app
                                    Exec=com.github.artemanufrij.webpin
                                    Keywords=webpin;webapp;internet;
                                    Icon=application-default-icon
                                    Terminal=false
                                    Type=Application
                                    Categories=Network;
                                    X-GNOME-FullName=webpin
                                    StartupWMClass=Webpin
                                    WebpinThemeColor=none""";

        private GLib.KeyFile file;
        public DesktopAppInfo info { get; set; }

        public string name { get; private set; }
        public string url { get; private set; }
        public string icon { get; private set; }
        public bool hide_on_close {
            get {
                this.file = new GLib.KeyFile();
                try {
                    file.load_from_file (info.filename, KeyFileFlags.NONE);
                    return file.get_string ("Desktop Entry", "WebpinStayOpen") == "true";
                } catch (Error e) {
                    warning (e.message);
                }
                return false;
            }
        }

        public bool mute_notifications {
            get {
                this.file = new GLib.KeyFile();
                try {
                    file.load_from_file (info.filename, KeyFileFlags.NONE);
                    return file.get_string ("Desktop Entry", "WebpinMuteNotifications") == "true";
                } catch (Error e) {
                    warning (e.message);
                }
                return false;
            }
        }

        public DesktopFile (string name, string url, string icon, bool stay_open) {
            this.name = name;
            this.url = url.replace ("%", "%%");
            this.icon = icon;

            file = new GLib.KeyFile();
            try {
                file.load_from_data (template, -1, GLib.KeyFileFlags.NONE);
            } catch (Error e) {
                warning (e.message);
            }
            //TODO: Category
            file.set_string ("Desktop Entry", "Name", name);
            file.set_string ("Desktop Entry", "GenericName", name);
            file.set_string ("Desktop Entry", "X-GNOME-FullName", name);
            file.set_string ("Desktop Entry", "Exec", "com.github.artemanufrij.webpin " + url);
            file.set_string ("Desktop Entry", "Icon", icon);
            file.set_string ("Desktop Entry", "StartupWMClass", url);
            file.set_string ("Desktop Entry", "WebpinStayOpen", stay_open.to_string ());
        }

        public DesktopFile.from_desktopappinfo(GLib.DesktopAppInfo info) {
            this.info = info;
            this.file = new GLib.KeyFile();
            try {
                file.load_from_file (info.filename, KeyFileFlags.NONE);
            } catch (Error e) {
                warning (e.message);
            }
            this.name = info.get_display_name ();
            this.icon = info.get_icon ().to_string ();
            try {
                this.url = file.get_string ("Desktop Entry", "Exec").substring (31);
            } catch (Error e) {
                warning (e.message);
            }
        }

        public bool edit_propertie (string propertie, string val) {
            bool return_value = false;
            try {
                string filename = GLib.Environment.get_user_data_dir () + "/applications/" + file.get_string("Desktop Entry", "Name") + "-webpin.desktop";
                file = new GLib.KeyFile();
                file.load_from_file (filename, KeyFileFlags.NONE);
                file.set_string ("Desktop Entry", propertie, val);
                return_value = file.save_to_file (filename);
            } catch (Error e) {
                warning (e.message);
            }

            return return_value;
        }

        public GLib.DesktopAppInfo save_to_file () {
            GLib.DesktopAppInfo return_value = null;
            try {
                string filename = GLib.Environment.get_user_data_dir () + "/applications/" +file.get_string("Desktop Entry", "Name") + "-webpin.desktop";
                print("Desktop file created: " + filename);
                file.save_to_file (filename);
                return_value = new GLib.DesktopAppInfo.from_filename (filename);
            } catch (Error e) {
                warning (e.message);
            }
            return return_value;
        }

        public bool delete_file () {
            try {
                string filename = GLib.Environment.get_user_data_dir () + "/applications/" +file.get_string("Desktop Entry", "Name") + "-webpin.desktop";
                File file = File.new_for_path (filename);
                file.delete ();
            } catch (Error e) {
                print(e.message + "\n");
                return false;
            }
            return true;
        }

        public static Gee.HashMap<string, GLib.DesktopAppInfo> get_webpin_applications () {

            var list = new Gee.HashMap<string, GLib.DesktopAppInfo>();

            foreach (GLib.AppInfo app in GLib.AppInfo.get_all()) {

                var desktop_app = new GLib.DesktopAppInfo(app.get_id ());

                //FIXME: This is not working, vala problem?
                //var keywords = desktop_app.get_keywords ();

                string keywords = desktop_app.get_string ("Keywords");

                if (keywords != null && keywords.contains ("webpin")) {
                    debug (desktop_app.get_name());
                    list.set(desktop_app.get_name(), desktop_app);
                }
            }
            return list;
        }

        public static GLib.DesktopAppInfo? get_app_by_url (string url) {
            foreach (GLib.AppInfo app in GLib.AppInfo.get_all()) {

                var desktop_app = new GLib.DesktopAppInfo(app.get_id ());

                var exec = desktop_app.get_string ("Exec").replace ("%%", "%");

                if (exec != null && exec.contains (url)) {
                    return desktop_app;
                }
            }
            return null;
        }

        public static Gee.HashMap<string, GLib.AppInfo> get_applications() {

            var list = new Gee.HashMap<string, GLib.AppInfo>();

            foreach (GLib.AppInfo app in GLib.AppInfo.get_all()) {
                debug (app.get_name());
                list.set(app.get_name(), app);
            }

            return list;
        }
    }
}
