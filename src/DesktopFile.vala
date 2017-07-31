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
                                    WebpinThemeColor=none""";


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
            file.set_string ("Desktop Entry", "Exec", "com.github.artemanufrij.webpin " + url);
            file.set_string ("Desktop Entry", "Icon", icon);
            file.set_string ("Desktop Entry", "StartupWMClass", url);
        }

        public DesktopFile.from_desktopappinfo(GLib.DesktopAppInfo info) {
            file = new GLib.KeyFile();
            file.load_from_file (info.filename, KeyFileFlags.NONE);
            this.name = info.get_display_name ();
            this.icon = info.get_icon ().to_string ();
            this.url = file.get_string ("Desktop Entry", "Exec").substring (31);
        }

        public bool edit_propertie (string propertie, string val) {
            string filename = GLib.Environment.get_user_data_dir () + "/applications/" +file.get_string("Desktop Entry", "Name") + "-webpin.desktop";
            file = new GLib.KeyFile();
            file.load_from_file (filename, KeyFileFlags.NONE);
            file.set_string ("Desktop Entry", propertie, val);
            return file.save_to_file (filename);
        }

        public GLib.DesktopAppInfo save_to_file () {
            string filename = GLib.Environment.get_user_data_dir () + "/applications/" +file.get_string("Desktop Entry", "Name") + "-webpin.desktop";
            print("Desktop file created: " + filename);
            file.save_to_file (filename);
            return new GLib.DesktopAppInfo.from_filename (filename);
        }

        public bool delete_file () {
            string filename = GLib.Environment.get_user_data_dir () + "/applications/" +file.get_string("Desktop Entry", "Name") + "-webpin.desktop";
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
                debug (app.get_name());
                list.set(app.get_name(), app);
            }

            return list;
        }
    }
}
