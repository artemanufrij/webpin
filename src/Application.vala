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
    public class WebpinApp : Granite.Application {

        static WebpinApp _instance = null;

        public static WebpinApp instance {
            get {
                if (_instance == null)
                    _instance = new WebpinApp ();
                return _instance;
            }
        }

        construct {
            program_name = "Image Burner";
            exec_name = "com.github.artemanufrij.webpin";
            application_id = "com.github.artemanufrij.webpin";
            app_launcher = application_id + ".desktop";
        }

        public Gtk.Window mainwindow;

        protected override void activate () {
            if (mainwindow != null) {
                mainwindow.present ();
                return;
            }

            mainwindow = new MainWindow (); 
            mainwindow.set_application(this);
        }
    }
}
static int main (string[] args) {

    Gtk.init (ref args);

    if (args.length < 2 || args[1] == "--about" || args[1] == "-d") {
        var app = Webpin.WebpinApp.instance;
        return app.run (args);
    } else {
        var app_info = Webpin.DesktopFile.get_app_by_url (args[1]);
        var app = new Webpin.WebAppWindow(app_info.get_display_name (), args[1]);
        app.show_all ();
    }

    Gtk.main ();
    return 0;
}
