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

namespace Webpin {
    public class WebpinApp : Gtk.Application {
        public string CACHE_FOLDER { get; private set; }

        static WebpinApp _instance = null;

        public static WebpinApp instance {
            get {
                if (_instance == null)
                    _instance = new WebpinApp ();
                return _instance;
            }
        }

        [CCode (array_length = false, array_null_terminated = true)]
        string[] ? arg_files = null;

        construct {
            this.flags |= GLib.ApplicationFlags.HANDLES_OPEN;
            this.flags |= ApplicationFlags.HANDLES_COMMAND_LINE;

            create_cache_folders ();
        }

        public Gtk.Window mainwindow { get; private set; default = null; }

        public void create_cache_folders () {
            CACHE_FOLDER = GLib.Path.build_filename (GLib.Environment.get_user_cache_dir (), "com.github.artemanufrij.webpin");
            try {
                File file = File.new_for_path (CACHE_FOLDER);
                if (!file.query_exists ()) {
                    file.make_directory ();
                }
            } catch (Error e) {
                warning (e.message);
            }
        }

        protected override void activate () {
            if (mainwindow != null) {
                mainwindow.present ();
                return;
            }
            mainwindow = new MainWindow ();
            mainwindow.set_application (this);
        }

        public override void open (File[] files, string hint) {
            start_webapp (files [0].get_uri ());
        }

        private void start_webapp (string url) {
            if (mainwindow != null ) {
                mainwindow.present ();
                return;
            }
            var app_info = Services.DesktopFilesManager.get_app_by_url (url);
            var desktop_file = new Webpin.DesktopFile.from_desktopappinfo (app_info);
            mainwindow = new Windows.WebApp (desktop_file);
            mainwindow.set_application (this);
        }

        public override int command_line (ApplicationCommandLine cmd) {
            command_line_interpreter (cmd);
            return 0;
        }

        private void command_line_interpreter (ApplicationCommandLine cmd) {
            string[] args_cmd = cmd.get_arguments ();
            unowned string[] args = args_cmd;

            bool new_app = false;
            bool remove_app = false;

            GLib.OptionEntry [] options = new OptionEntry [4];
            options [0] = { "new", 0, 0, OptionArg.NONE, ref new_app, "Create new Webapp", null };
            options [1] = { "remove", 0, 0, OptionArg.NONE, ref remove_app, "Remove Webapp", null };
            options [2] = { "", 0, 0, OptionArg.STRING_ARRAY, ref arg_files, null, "[URI...]" };
            options [3] = { null };

            var opt_context = new OptionContext ("actions");
            opt_context.add_main_entries (options, null);
            try {
                opt_context.parse (ref args);
            } catch (Error err) {
                warning (err.message);
                return;
            }

            if (new_app) {
                if (new_app) {
                    activate ();
                    (mainwindow as MainWindow).show_assistant ();
                }
                return;
            }

            File[] files = null;
            foreach (string arg_file in arg_files) {
                files += (File.new_for_uri (arg_file));
            }

            if (files != null && files.length > 0) {
                if (remove_app) {
                    var app_info = Services.DesktopFilesManager.get_app_by_url (files [0].get_uri ());
                    var desktop_file = new Webpin.DesktopFile.from_desktopappinfo (app_info);
                    desktop_file.delete_file ();
                } else {
                    open (files, "");
                }
                return;
            }

            activate ();
        }
    }
}

static int main (string[] args) {
    Gtk.init (ref args);
    var app = Webpin.WebpinApp.instance;

    bool has_new_arg = false;

    foreach (var arg in args) {
        if (arg == "--new") {
            has_new_arg = true;
        }
    }

    if (args.length > 1 && !has_new_arg) {
        var checksum = new GLib.Checksum (GLib.ChecksumType.MD5);
        checksum.update (args[1].data, args[1].length);
        var id = "a" + checksum.get_string ().substring (0, 5) + "a.artemanufrij.webpin";
        app.application_id = id;
    } else {
        app.application_id = "com.github.artemanufrij.webpin";
    }
    return app.run (args);
}
