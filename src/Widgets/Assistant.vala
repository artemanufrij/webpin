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
    public class Assistant : Gtk.Box {

        public enum assistant_mode { new_app, edit_app }

        public signal void application_created (GLib.DesktopAppInfo? new_file);
        public signal void application_edited (GLib.DesktopAppInfo? new_file);

        private Gtk.Label message;
        private Gtk.Button icon_button;
        private Gtk.Entry app_name_entry;
        private Gtk.Entry app_url_entry;
        private Gtk.Entry icon_name_entry;
        private Gtk.CheckButton save_cookies_check;
        private Gtk.CheckButton save_password_check;
        private Gtk.Popover icon_selector_popover;
        private Gtk.FileChooserDialog file_chooser;
        private Gtk.Button accept_button;
        private GLib.Regex protocol_regex;
        private Gee.HashMap<string, GLib.AppInfo> apps;

        private string default_app_icon = "artemanufrij.webpin";

        private bool app_name_valid = false;
        private bool app_url_valid = false;
        private bool app_icon_valid = true;

        private assistant_mode mode { get; set; default = assistant_mode.new_app; }

        public Assistant () {

            GLib.Object (orientation: Gtk.Orientation.VERTICAL);
            apps = DesktopFile.get_applications ();

            this.margin = 15;

            try {
                //http(s)://(words or numbers)(port and numbers)
                this.protocol_regex = new Regex ("""https?\:\/\/[\w+\d+]((\:\d+)?\/\S*)?""");
            } catch (RegexError e) {
                critical ("%s", e.message);
            }

            //welcome message
            message = new Gtk.Label (_("Create a new web app"));
            message.get_style_context ().add_class ("h2");
            //app information
            icon_button = new Gtk.Button ();
            icon_button.set_image (new Gtk.Image.from_icon_name (default_app_icon, Gtk.IconSize.DIALOG) );
            icon_button.halign = Gtk.Align.END;

            app_name_entry = new Gtk.Entry ();
            app_name_entry.set_placeholder_text (_("Application name"));

            app_url_entry = new Gtk.Entry ();
            app_url_entry.set_placeholder_text (_("http://myapp.domain"));

            //icon selector popover
            icon_selector_popover = new Gtk.Popover (icon_button);
            icon_selector_popover.modal = true;
            icon_selector_popover.position = Gtk.PositionType.BOTTOM;

            var popover_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);

            icon_name_entry = new Gtk.Entry ();
            icon_name_entry.set_placeholder_text (_("theme icon name"));

            var or_label = new Gtk.Label (_("or"));
            var icon_chooser_button = new Gtk.Button.with_label(_("Set from file..."));
            icon_chooser_button.get_style_context ().add_class ("suggested-action");

            popover_box.margin = 10;
            popover_box.pack_start (icon_name_entry, true, false, 0);
            popover_box.pack_start (or_label, true, false, 0);
            popover_box.pack_end (icon_chooser_button, true, false, 0);

            icon_chooser_button.grab_focus ();

            icon_selector_popover.add (popover_box);

            //TODO: categories
            //combobox

            //checkbuttons
            save_cookies_check = new Gtk.CheckButton.with_label (_("Save cookies"));
            save_cookies_check.active = true;
            save_password_check = new Gtk.CheckButton.with_label (_("Save login information"));
            save_password_check.active = false;

            //app information section
            var app_input_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
            app_input_box.halign = Gtk.Align.START;
            app_input_box.pack_start (app_name_entry, false, false, 0);
            app_input_box.pack_start (app_url_entry, false, false, 0);
            //app_input_box.pack_start (app_category_combo, true, false, 0);

            var app_info_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
            app_info_box.pack_start (icon_button, false, false, 3);
            app_info_box.pack_start (app_input_box, false, false, 3);
            app_info_box.halign = Gtk.Align.CENTER;

            //app options
            var app_options_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
            app_options_box.pack_start (save_cookies_check, true, false, 0);
            app_options_box.pack_start (save_password_check, true, false, 0);
            app_options_box.halign = Gtk.Align.CENTER;


            //create button
            accept_button = new Gtk.Button.with_label(_("Save app"));
            accept_button.halign = Gtk.Align.END;
            accept_button.get_style_context ().add_class ("suggested-action");
            accept_button.set_sensitive (false);
            accept_button.activate.connect (on_accept);
            accept_button.clicked.connect (on_accept);

            //all sections together
            pack_start (message, true, false, 0);
            pack_start (app_info_box, true, false, 0);
            pack_start (app_options_box, true, false, 0);
            pack_end (accept_button, false, false, 0);

            //signals and handlers
            icon_button.clicked.connect(() => {
                icon_selector_popover.show_all();
            });

            app_url_entry.changed.connect (()=>{
                if (!this.protocol_regex.match (app_url_entry.get_text())) {
                    app_url_entry.get_style_context ().add_class ("error");
                    app_url_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-information");
                    app_url_entry.set_icon_tooltip_text(Gtk.EntryIconPosition.SECONDARY, _("url must start with http:// or https://"));
                    app_url_valid = false;
                } else {
                    app_url_entry.get_style_context ().remove_class ("error");
                    app_url_valid = true;
                }
                validate ();
            });

            app_name_entry.changed.connect (()=>{
                if (mode == assistant_mode.new_app && DesktopFile.get_applications().has_key (app_name_entry.get_text()) ) {
                    app_name_entry.get_style_context ().add_class ("error");
                    app_name_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "dialog-information");
                    app_name_entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("App already exist"));
                    app_name_valid = false;
                } else {
                    app_name_entry.get_style_context ().remove_class ("error");
                    app_name_valid = true;
                }
                validate ();
            });

            icon_chooser_button.activate.connect (on_icon_chooser_activate);
            icon_chooser_button.clicked.connect (on_icon_chooser_activate);

            icon_name_entry.changed.connect (update_app_icon);
        }


        private void update_app_icon () {
            string icon = icon_name_entry.get_text ();

            if (icon == "") {
                app_icon_valid = true;
                validate ();
                return;
            }

            //if is a file uri
            if (icon.contains("/")) {
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
	            } finally {
                    if (pix != null)
                        icon_button.set_image (new Gtk.Image.from_pixbuf (pix));
                }
            } else {
                icon_button.set_image (new Gtk.Image.from_icon_name (icon, Gtk.IconSize.DIALOG) );
            }

            validate ();
        }

        private void on_icon_chooser_activate () {
	        var filter = new Gtk.FileFilter ();

	        filter.set_filter_name (_("Images"));
	        filter.add_pattern ("*.png");
	        filter.add_pattern ("*.svg");
	        filter.add_pattern ("*.jpg");
	        filter.add_pattern ("*.jpeg");
	        filter.add_pattern ("*.PNG");
	        filter.add_pattern ("*.SVG");
	        filter.add_pattern ("*.JPG");
	        filter.add_pattern ("*.JPEG");

            file_chooser = new Gtk.FileChooserDialog ("", null,
                                                       Gtk.FileChooserAction.OPEN,
                                                       _("Cancel"), Gtk.ResponseType.CANCEL,
                                                       _("Open"), Gtk.ResponseType.ACCEPT);
            file_chooser.set_select_multiple(false);
            file_chooser.add_filter (filter);

            var preview = new Gtk.Image();
            preview.valign = Gtk.Align.START;

            file_chooser.update_preview.connect ( ()=> {

                string filename = file_chooser.get_preview_filename();
                Gdk.Pixbuf pix = null;

                if (filename != null) {
                    try {
                        pix = new Gdk.Pixbuf.from_file_at_size (filename, 128, 128);
			        } catch (GLib.Error error) {
                         warning ("There was a problem loading preview.");
		            }
                }

                if (pix != null){
                    preview.set_from_pixbuf (pix);
                    file_chooser.set_preview_widget_active (true);
                    file_chooser.set_preview_widget (preview);
                } else {
                    file_chooser.set_preview_widget_active (false);
                }
            });

            if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {

                icon_name_entry.set_text(file_chooser.get_filename ());
                file_chooser.destroy ();
            }
            file_chooser.destroy ();
        }


        private void validate () {
            if (app_icon_valid && app_name_valid && app_url_valid) {
                accept_button.set_sensitive (true);
                return;
            }
            accept_button.set_sensitive (false);
        }


        public void reset_fields () {
            icon_name_entry.set_text ("");
            app_name_entry.set_text ("");
            app_name_entry.set_sensitive (true);
            app_url_entry.set_text ("");
            app_name_entry.get_style_context ().remove_class ("error");
            app_url_entry.get_style_context ().remove_class ("error");
            icon_button.set_image (new Gtk.Image.from_icon_name (default_app_icon, Gtk.IconSize.DIALOG) );
            mode = assistant_mode.new_app;
        }

        private void on_accept () {

            string icon = icon_name_entry.get_text ();
            string name = app_name_entry.get_text ();
            string url = app_url_entry.get_text ();

            if (icon == "")
                icon = default_app_icon;

            if (app_icon_valid && app_name_valid && app_url_valid) {
                var desktop_file = new DesktopFile (name, url, icon);
                switch (mode) {
                    case assistant_mode.new_app:
                        application_created (desktop_file.save_to_file ());
                        break;
                    case assistant_mode.edit_app:
                        application_edited (desktop_file.save_to_file ());
                        break;
                }
            }
        }

        public void edit_desktop_file (DesktopFile desktop_file) {
            mode = assistant_mode.edit_app;
            app_name_entry.text = desktop_file.name;
            app_name_entry.set_sensitive (false);
            app_url_entry.text = desktop_file.url;
            icon_name_entry.text = desktop_file.icon;
            update_app_icon ();
        }
    }
}
