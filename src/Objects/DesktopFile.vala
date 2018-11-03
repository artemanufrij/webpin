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

namespace Webpin {
    public class DesktopFile : GLib.Object {

        string template = """
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
                            X-GNOME-Gettext-Domain=com.github.artemanufrij.webpin
                            X-GNOME-UsesNotifications=true
                            StartupWMClass=Webpin
                            X-Webpin-PrimaryColor=rgba (222,222,222,1)
                            X-Webpin-View-Mode=default
                            Actions=Remove;

                            [Desktop Action Remove]
                            Name=Remove Webapp
                            Exec=com.github.artemanufrij.webpin --remove
                            Icon=edit-delete-symbolic
                            """;

        GLib.KeyFile file;

        public DesktopAppInfo info { get; set; }

        public string name { get; private set; }
        public string url { get; private set; }
        public string icon { get; private set; }
        public bool hide_on_close {
            get {
                try {
                    file.load_from_file (info.filename, KeyFileFlags.NONE);
                    return file.get_string ("Desktop Entry", "X-Webpin-StayOpen") == "true";
                } catch (Error err) {
                    warning (err.message);
                }
                return false;
            }
        }

        Gdk.RGBA? _color;
        public Gdk.RGBA? color {
            get {
                if (_color == null) {
                    Gdk.RGBA return_value = {0, 0, 0, 1};
                    try {
                        file.load_from_file (info.filename, KeyFileFlags.NONE);
                        var property = file.get_string ("Desktop Entry", "X-Webpin-PrimaryColor");
                        if (property == "" || !return_value.parse (property)) {
                            return null;
                        }
                    } catch (Error err) {
                        warning (err.message);
                        return null;
                    }
                    _color = return_value;
                }
                return _color;
            } set {
                if (value != null) {
                    _color = value;
                    var color = "rgba(%d,%d,%d,1)".printf ((int)(value.red * 255), (int)(value.green * 255), (int)(value.blue * 255));
                    edit_property ("X-Webpin-PrimaryColor", color);
                } else {
                    edit_property ("X-Webpin-PrimaryColor", "none");
                }
            }
        }

        string _view_mode = "";
        public string view_mode {
            get {
                try {
                    file.load_from_file (info.filename, KeyFileFlags.NONE);
                    _view_mode = file.get_string ("Desktop Entry", "X-Webpin-View-Mode");
                } catch (Error err) {
                    warning (err.message);
                }
                return _view_mode;
            } set {
                edit_property ("X-Webpin-View-Mode", value);
                _view_mode = value;
            }
        }

        public DesktopFile (string name, string url, string icon, bool stay_open, bool minimal_ui) {
            this.name = name;
            this.url = url.replace ("%", "%%");
            this.icon = icon;

            file = new GLib.KeyFile();
            try {
                file.load_from_data (template, -1, GLib.KeyFileFlags.NONE);
            } catch (Error err) {
                warning (err.message);
            }

            file.set_string ("Desktop Entry", "Name", name);
            file.set_string ("Desktop Entry", "GenericName", name);
            file.set_string ("Desktop Entry", "X-GNOME-FullName", name);
            file.set_string ("Desktop Entry", "Exec", "com.github.artemanufrij.webpin " + url);
            file.set_string ("Desktop Entry", "Icon", icon);
            file.set_string ("Desktop Entry", "StartupWMClass", url);
            file.set_string ("Desktop Entry", "X-Webpin-StayOpen", stay_open.to_string ());
            file.set_string ("Desktop Entry", "X-Webpin-View-Mode", minimal_ui ? "minimal" : "default");
            file.set_string ("Desktop Action Remove", "Exec", "com.github.artemanufrij.webpin --remove " + url);
        }

        public DesktopFile.from_desktopappinfo (GLib.DesktopAppInfo info) {
            this.info = info;
            this.file = new GLib.KeyFile();
            try {
                file.load_from_file (info.filename, KeyFileFlags.NONE);
            } catch (Error err) {
                warning (err.message);
            }
            this.name = info.get_display_name ();
            this.icon = info.get_icon ().to_string ();
            try {
                this.url = file.get_string ("Desktop Entry", "Exec").substring (31);
            } catch (Error err) {
                warning (err.message);
            }
        }

        public bool edit_property (string property, string val) {
            bool return_value = false;
            try {
                string filename = GLib.Environment.get_user_data_dir () + "/applications/" + file.get_string ("Desktop Entry", "Name") + "-webpin.desktop";
                file = new GLib.KeyFile ();
                file.load_from_file (filename, KeyFileFlags.NONE);
                file.set_string ("Desktop Entry", property, val);
                return_value = file.save_to_file (filename);
            } catch (Error err) {
                warning (err.message);
            }

            return return_value;
        }

        public new string get_property (string property) {
            string return_value = "";
            try {
                string filename = GLib.Environment.get_user_data_dir () + "/applications/" + file.get_string ("Desktop Entry", "Name") + "-webpin.desktop";
                file = new GLib.KeyFile ();
                file.load_from_file (filename, KeyFileFlags.NONE);
                return_value = file.get_string ("Desktop Entry", property);
            } catch (Error err) {
                warning (err.message);
            }

            return return_value;
        }

        public GLib.DesktopAppInfo save_to_file () {
            GLib.DesktopAppInfo return_value = null;
            try {
                string filename = GLib.Environment.get_user_data_dir () + "/applications/" +file.get_string ("Desktop Entry", "Name") + "-webpin.desktop";
                file.save_to_file (filename);
                return_value = new GLib.DesktopAppInfo.from_filename (filename);
            } catch (Error err) {
                warning (err.message);
            }
            return return_value;
        }

        public bool delete_file () {
            try {
                string filename = GLib.Environment.get_user_data_dir () + "/applications/" +file.get_string ("Desktop Entry", "Name") + "-webpin.desktop";
                File file = File.new_for_path (filename);
                file.delete ();
            } catch (Error err) {
                warning (err.message);
                return false;
            }
            return true;
        }
    }
}
