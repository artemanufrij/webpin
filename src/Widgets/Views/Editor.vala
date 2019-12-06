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

namespace Webpin.Widgets.Views {
    public class Editor : Gtk.Box {
        public enum assistant_mode { new_app, edit_app }

        public signal void application_created (GLib.DesktopAppInfo ? new_file);
        public signal void application_edited (GLib.DesktopAppInfo ? new_file);

        Gtk.Label message;
        Gtk.Button icon_button;
        Gtk.Entry app_name_entry;
        Gtk.Entry app_url_entry;
        Gtk.Entry icon_name_entry;
        Gtk.CheckButton save_cookies_check;
        Gtk.CheckButton save_password_check;
        Gtk.CheckButton stay_open_when_closed;
        Gtk.CheckButton minimal_view_mode;
        Gtk.Popover icon_selector_popover;
        Gtk.FileChooserDialog file_chooser;
        Gtk.Button accept_button;
        Gtk.ColorButton primary_color_button;
        GLib.Regex protocol_regex;
        Gee.HashMap<string, GLib.AppInfo> apps;

        private string default_app_icon = "com.github.artemanufrij.webpin";

        private bool app_name_valid = false;
        private bool app_url_valid = false;
        private bool app_icon_valid = true;

        private assistant_mode mode { get; set; default = assistant_mode.new_app; }

        Gdk.RGBA default_color;

        string tmp_icon_file;
        string tmp_icon_ext;
        uint grab_timer = 0;

        construct {
            default_color = { 0, 0, 0, 1 };
            default_color.parse ("rgba (222, 222, 222, 1)");
        }

        public Editor () {
            GLib.Object (orientation : Gtk.Orientation.VERTICAL);
            apps = Services.DesktopFilesManager.get_applications ();

            this.margin = 15;

            try {
                this.protocol_regex = new Regex ("(https?://|file:///)[\\w\\d]");
            } catch (RegexError e) {
                critical ("%s", e.message);
            }

            //welcome message
            message = new Gtk.Label (""); // set in {@link reset_fields} or {@link edit_desktop_file}
            message.get_style_context ().add_class ("h2");
            //app information
            icon_button = new Gtk.Button ();
            icon_button.set_image (new Gtk.Image.from_icon_name (default_app_icon, Gtk.IconSize.DIALOG) );
            icon_button.halign = Gtk.Align.END;

            app_name_entry = new Gtk.Entry ();
            app_name_entry.set_placeholder_text (_ ("Application name"));

            app_url_entry = new Gtk.Entry ();
            app_url_entry.width_request = 320;
            app_url_entry.set_placeholder_text (_ ("https://myapp.domain or file:///my/local/file"));

            //icon selector popover
            icon_selector_popover = new Gtk.Popover (icon_button);
            icon_selector_popover.modal = true;
            icon_selector_popover.position = Gtk.PositionType.BOTTOM;

            var popover_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);

            icon_name_entry = new Gtk.Entry ();
            icon_name_entry.set_placeholder_text (_ ("theme icon name"));

            var or_label = new Gtk.Label (_ ("or"));
            var icon_chooser_button = new Gtk.Button.with_label (_ ("Set from file…"));
            icon_chooser_button.get_style_context ().add_class ("suggested-action");

            popover_box.margin = 10;
            popover_box.pack_start (icon_name_entry, true, false, 0);
            popover_box.pack_start (or_label, true, false, 0);
            popover_box.pack_end (icon_chooser_button, true, false, 0);

            icon_chooser_button.grab_focus ();

            icon_selector_popover.add (popover_box);

            primary_color_button = new Gtk.ColorButton.with_rgba (default_color);
            primary_color_button.use_alpha = false;
            primary_color_button.color_activated.connect ((color) => {
                stdout.printf ("COLOR %s\n", color.to_string ());
            });

            //checkbuttons
            save_cookies_check = new Gtk.CheckButton.with_label (_ ("Save cookies"));
            save_cookies_check.active = true;
            save_password_check = new Gtk.CheckButton.with_label (_ ("Save login information"));
            save_password_check.active = false;
            stay_open_when_closed = new Gtk.CheckButton.with_label (_ ("Run in background if closed"));
            stay_open_when_closed.active = false;
            minimal_view_mode = new Gtk.CheckButton.with_label (_("Use minimal UI"));
            minimal_view_mode.active = false;


            //app information section
            var app_input_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
            app_input_box.halign = Gtk.Align.START;
            app_input_box.pack_start (app_name_entry, false, false, 0);
            app_input_box.pack_start (app_url_entry, false, false, 0);

            var app_info_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
            app_info_box.pack_start (icon_button, false, false, 3);
            app_info_box.pack_start (app_input_box, false, false, 3);
            app_info_box.pack_start (primary_color_button, false, false, 3);
            app_info_box.halign = Gtk.Align.CENTER;

            //app options
            var app_options_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
            app_options_box.pack_start (save_cookies_check, true, false, 0);
            app_options_box.pack_start (save_password_check, true, false, 0);
            app_options_box.pack_start (stay_open_when_closed, true, false, 0);
            app_options_box.pack_start (minimal_view_mode, true, false, 0);
            app_options_box.halign = Gtk.Align.CENTER;

            //create button
            accept_button = new Gtk.Button.with_label (_ ("Save app"));
            accept_button.halign = Gtk.Align.END;
            accept_button.get_style_context ().add_class ("suggested-action");
            accept_button.sensitive = false;
            accept_button.activate.connect (on_accept);
            accept_button.clicked.connect (on_accept);

            //all sections together
            pack_start (message, true, false, 0);
            pack_start (app_info_box, true, false, 0);
            pack_start (app_options_box, true, false, 0);
            pack_end (accept_button, false, false, 0);

            //signals and handlers
            icon_button.clicked.connect (() => {
                icon_selector_popover.show_all ();
            });

            app_url_entry.changed.connect (() => {
                if (!this.protocol_regex.match (app_url_entry.get_text ())) {
                    reset_grab_color_and_icon ();
                    app_url_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error");
                    app_url_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _ ("url must start with http:// or https:// or file:///"));
                    app_url_valid = false;
                    // widget error class is set in {@link updateFormStatus}
                } else {
                    grab_color_and_icon ();
                    app_url_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
                    app_url_valid = true;
                }
                updateFormStatus ();
            });

            app_name_entry.changed.connect (() => {
                if (mode == assistant_mode.new_app && Services.DesktopFilesManager.get_applications ().has_key (app_name_entry.get_text ())) {
                    app_name_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-error");
                    app_name_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _ ("App already exist"));
                    app_name_valid = false;
                    // widget error class is set in {@link updateFormStatus}
                } else {
                    app_name_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
                    app_name_valid = true;
                }
                updateFormStatus ();
            });

            icon_chooser_button.activate.connect (on_icon_chooser_activate);
            icon_chooser_button.clicked.connect (on_icon_chooser_activate);

            icon_name_entry.changed.connect (update_app_icon);
        }

        private void grab_color_and_icon () {
            reset_grab_color_and_icon ();
            grab_timer = Timeout.add (
                500,
                () => {
                    new Thread<void*> (
                        "grab_color_and_icon",
                        () => {
                            if (tmp_icon_file != "" ) {
                                FileUtils.remove (tmp_icon_file);
                                tmp_icon_file = "";
                            }

                            var url = app_url_entry.text;
                            var session = new Soup.Session.with_options ("user_agent", "WebPin/0.1.0 (https://github.com/artemanufrij/webpin)");
                            session.timeout = 2;
                            var msg = new Soup.Message ("GET", url);
                            session.send_message (msg);

                            if (msg.status_code == 200) {
                                var body = (string)msg.response_body.data;

                                Regex regex = null;
                                try {
                                    regex = new Regex ("(?<=<meta name=\"theme-color\" content=\")#[0-9a-fA-F]{6}");
                                } catch (Error err) {
                                    warning (err.message);
                                }

                                MatchInfo match_info = null;
                                if (regex != null && regex.match (body, 0, out match_info)) {
                                    var result = match_info.fetch (0);
                                    Gdk.RGBA return_value = {0, 0, 0, 1};
                                    if (return_value.parse (result)) {
                                        Idle.add (
                                            () => {
                                                primary_color_button.set_rgba (return_value);
                                                return false;
                                            });
                                    }
                                }

                                if (tmp_icon_file == "") {
                                    try {
                                        regex = new Regex ("(?<=\"fluid-icon\" href=\")[/\\w\\.:\\-]*");
                                        if (regex.match (body, 0, out match_info)) {
                                            var icon_path = format_icon_path (url, match_info.fetch (0));
                                            download_icon (icon_path);
                                        }
                                    } catch (Error err) {
                                        warning (err.message);
                                    }
                                }

                                if (tmp_icon_file == "") {
                                    try {
                                        regex = new Regex ("(rel=\"icon\").*href=\"([\\-/\\w]*64.png)");
                                        if (regex.match (body, 0, out match_info)) {
                                            var icon_path = format_icon_path (url,  match_info.fetch (match_info.get_match_count () - 1));
                                            download_icon (icon_path);
                                        }
                                    } catch (Error err) {
                                        warning (err.message);
                                    }
                                }

                                if (tmp_icon_file == "") {
                                    try {
                                        regex = new Regex ("(rel=\"icon\").*href=\"([\\-/\\w]*96.png)");
                                        if (regex.match (body, 0, out match_info)) {
                                            var icon_path = format_icon_path (url,  match_info.fetch (match_info.get_match_count () - 1));
                                            download_icon (icon_path);
                                        }
                                    } catch (Error err) {
                                        warning (err.message);
                                    }
                                }

                                if (tmp_icon_file == "") {
                                    try {
                                        regex = new Regex ("(\"apple-touch-icon\").*href=\"([\\-/\\w]*.png)");
                                        if (regex.match (body, 0, out match_info)) {
                                            var icon_path = format_icon_path (url, match_info.fetch (match_info.get_match_count () - 1));
                                            download_icon (icon_path);
                                        }
                                    } catch (Error err) {
                                        warning (err.message);
                                    }
                                }

                                if (tmp_icon_file == "") {
                                    try {
                                        regex = new Regex ("(?<=\"mask-icon\" href=\")[/\\w\\.:\\-]*");
                                        if (regex.match (body, 0, out match_info)) {
                                            var icon_path = format_icon_path (url, match_info.fetch (0));
                                            download_icon (icon_path);
                                        }
                                    } catch (Error err) {
                                        warning (err.message);
                                    }
                                }

                                stdout.printf ("Downloaded icon: '%s'", tmp_icon_file);
                                if (tmp_icon_file != "") {
                                    Idle.add (
                                        () => {
                                            icon_name_entry.set_text (tmp_icon_file);
                                            return false;
                                        });
                                }
                            }
                            msg.dispose ();
                            session.dispose ();

                            return null;
                        });


                    reset_grab_color_and_icon ();
                    return false;
                });
        }

        private string format_icon_path (string base_url, string icon_path) {
            string return_value = icon_path;

            if (!return_value.has_prefix ("http")) {
                return_value = Path.build_filename (base_url, icon_path);
            }

            return return_value;
        }

        private void reset_grab_color_and_icon () {
            if (grab_timer != 0) {
                Source.remove (grab_timer);
                grab_timer = 0;
            }
        }

        public bool download_icon (string url) {
            var session = new Soup.Session.with_options ("user_agent", "WebPin/0.1.0 (https://github.com/artemanufrij/webpin)");
            session.timeout = 2;
            var msg = new Soup.Message ("GET", url);
            session.send_message (msg);
            if (msg.status_code == 200) {
                tmp_icon_ext = ".png";
                if (url.has_suffix (".svg")) {
                    tmp_icon_ext = ".svg";
                }

                tmp_icon_file = GLib.Path.build_filename (Environment.get_tmp_dir (), Random.next_int ().to_string () + tmp_icon_ext);

                var s_file = File.new_for_uri (url);
                var d_file = File.new_for_path (tmp_icon_file);

                bool copy_done = false;
                try {
                    copy_done = s_file.copy (d_file, FileCopyFlags.OVERWRITE);
                } catch (Error err) {
                        warning (err.message);
                }
                if (copy_done && tmp_icon_ext != ".svg") {
                    try {
                        var pixbuf = new Gdk.Pixbuf.from_file (tmp_icon_file);
                        if (pixbuf.width < 48 || pixbuf.height < 48) {
                            FileUtils.remove (tmp_icon_file);
                            tmp_icon_file = "";
                            tmp_icon_ext = "";
                        }
                    } catch (Error err) {
                        warning (err.message);
                    }
                }
            }
            msg.dispose ();
            session.dispose ();
            return true;
        }

        private void update_app_icon () {
            string icon = icon_name_entry.get_text ();

            if (icon == "") {
                icon_button.set_image (new Gtk.Image.from_icon_name (default_app_icon, Gtk.IconSize.DIALOG));
                app_icon_valid = true;
                updateFormStatus ();
                return;
            }

            //if is a file uri
            if (icon.has_prefix ("/")) {
                Gdk.Pixbuf pix = null;
                try {
                    pix = new Gdk.Pixbuf.from_file_at_size (icon, 48, 48);
                    app_icon_valid = true;
                } catch (GLib.Error error) {
                    app_icon_valid = false;
                    try {
                        Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default ();
                        pix = icon_theme.load_icon ("image-missing", 48, Gtk.IconLookupFlags.FORCE_SIZE);
                    } catch (GLib.Error err) {
                        warning ("Getting selection-checked icon from theme failed");
                    }
                }
                if (pix != null) {
                    icon_button.set_image (new Gtk.Image.from_pixbuf (pix));
                }
            } else {
                var img = new Gtk.Image.from_icon_name (icon, Gtk.IconSize.DIALOG);
                icon_button.set_image (img);
                // TODO: check if the icon name is a valid one - otherwise app_icon_valid = false
            }

            updateFormStatus ();
        }

        private void on_icon_chooser_activate () {
            var filter = new Gtk.FileFilter ();
            filter.set_filter_name (_ ("Images"));
            filter.add_mime_type ("image/*");

            file_chooser = new Gtk.FileChooserDialog (_("Choose icon"), WebpinApp.instance.mainwindow,
                                                      Gtk.FileChooserAction.OPEN,
                                                      _ ("Cancel"), Gtk.ResponseType.CANCEL,
                                                      _ ("Open"), Gtk.ResponseType.ACCEPT);
            file_chooser.set_select_multiple (false);
            file_chooser.add_filter (filter);

            var preview = new Gtk.Image ();
            preview.valign = Gtk.Align.START;

            file_chooser.update_preview.connect (
                ()=> {
                    string filename = file_chooser.get_preview_filename ();
                    Gdk.Pixbuf pix = null;

                    if (filename != null) {
                        try {
                            pix = new Gdk.Pixbuf.from_file_at_size (filename, 128, 128);
                        } catch (GLib.Error error) {
                            warning ("There was a problem loading preview.");
                        }
                    }

                    if (pix != null) {
                        preview.set_from_pixbuf (pix);
                        file_chooser.set_preview_widget_active (true);
                        file_chooser.set_preview_widget (preview);
                    } else {
                        file_chooser.set_preview_widget_active (false);
                    }
                });

            if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
                stdout.printf ("Icon file chosen: '%s'\n", file_chooser.get_filename ());
                icon_name_entry.set_text (file_chooser.get_filename ());
                file_chooser.destroy ();
            }
            file_chooser.destroy ();
        }

        private void update_form_status () {
            set_class(app_name_entry, "error", !app_name_valid);
            set_class(app_url_entry, "error", !app_url_valid);
            set_class(icon_button, "destructive-action", !app_icon_valid);

            accept_button.sensitive = app_icon_valid && app_name_valid && app_url_valid;
        }

        public void reset_fields () {
            tmp_icon_file = "";
            icon_name_entry.set_text ("");
            app_name_entry.sensitive = true;
            app_name_entry.set_text ("");
            app_url_entry.set_text ("");
            icon_button.set_image (new Gtk.Image.from_icon_name (default_app_icon, Gtk.IconSize.DIALOG));
            minimal_view_mode.active = false;
            mode = assistant_mode.new_app;
            message.set_text (_ ("Create a new web app"));

            app_name_valid = false;
            app_url_valid = false;
            app_icon_valid = true;
            set_class(app_name_entry, "error", false); // we don't want to display as error right away (only after change)
            set_class(app_url_entry, "error", false);
            set_class(icon_button, "destructive-action", false);
        }

        private void on_accept () {
            string icon = icon_name_entry.get_text ();

            if (icon.has_prefix("/")) {
                File file = File.new_for_path (icon);
                if (file.query_exists ()) {
                    var new_icon = GLib.Path.build_filename (WebpinApp.instance.CACHE_FOLDER, app_name_entry.get_text () + tmp_icon_ext);
                    stdout.printf ("Copying temp icon '%s' to '%s'\n", icon, new_icon);
                    uint8[] content;
                    try {
                        FileUtils.get_data (icon, out content);
                        FileUtils.set_data (new_icon, content);
                    } catch (Error err) {
                        warning (err.message);
                    }
                    if (tmp_icon_file != "") {
                        FileUtils.remove (tmp_icon_file);
                    }
                    icon = new_icon;
                }
            } else if (icon == "") {
                icon = default_app_icon;
            }

            string name = app_name_entry.get_text ();
            string url = app_url_entry.get_text ().replace ("%", "%%");

            if (app_icon_valid && app_name_valid && app_url_valid) {
                stdout.printf ("Saving '%s' with icon='%s'\n", name, icon);
                var desktop_file = new DesktopFile (name, url, icon, stay_open_when_closed.active, minimal_view_mode.active);
                switch (mode) {
                    case assistant_mode.new_app :
                        application_created (desktop_file.save_to_file ());
                        break;
                    case assistant_mode.edit_app :
                        application_edited (desktop_file.save_to_file ());
                        break;
                }
                stdout.printf ("Custom Color %s\n", primary_color_button.rgba.to_string ());
                desktop_file.color = primary_color_button.rgba;
            }
        }

        public void edit_desktop_file (DesktopFile ? desktop_file) {
            if (desktop_file == null) {
                reset_fields ();
            } else {
                stdout.printf ("Opening editor for '%s'\n", desktop_file.name);
                mode = assistant_mode.edit_app;
                message.set_text (_ ("Edit web app"));
                app_name_entry.text = desktop_file.name;
                app_name_entry.sensitive = false;
                app_url_entry.text = desktop_file.url.replace ("%%", "%");
                icon_name_entry.text = desktop_file.icon;
                stay_open_when_closed.active = desktop_file.hide_on_close;
                minimal_view_mode.active = desktop_file.view_mode == "minimal";
                if (desktop_file.color != null) {
                    primary_color_button.set_rgba (desktop_file.color);
                } else {
                    primary_color_button.set_rgba (default_color);
                }
                reset_grab_color_and_icon ();
                update_app_icon ();
                updateFormStatus();
            }
        }
    }
}

public void set_class(Gtk.Widget widget, string class_name, bool flag) {
    if (flag)
        widget.get_style_context().add_class(class_name);
    else
        widget.get_style_context().remove_class(class_name);
}
