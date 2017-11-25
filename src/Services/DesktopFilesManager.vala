/*-
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

namespace Webpin.Services {
    public class DesktopFilesManager {
        public static GLib.DesktopAppInfo? get_app_by_url (string url) {
            foreach (GLib.AppInfo app in GLib.AppInfo.get_all ()) {
                var desktop_app = new GLib.DesktopAppInfo (app.get_id ());
                var exec = desktop_app.get_string ("Exec");
                if (exec != null) {
                    exec = exec.replace ("%%", "%");
                    if (exec.contains (url)) {
                        return desktop_app;
                    }
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

        public static Gee.HashMap<string, GLib.DesktopAppInfo> get_webpin_applications () {
            var list = new Gee.HashMap<string, GLib.DesktopAppInfo>();

            foreach (GLib.AppInfo app in GLib.AppInfo.get_all()) {
                var desktop_app = new GLib.DesktopAppInfo(app.get_id ());

                string keywords = desktop_app.get_string ("Keywords");
                if (keywords != null && keywords.contains ("webpin")) {
                    list.set(desktop_app.get_name(), desktop_app);
                }
            }
            return list;
        }
    }
}
