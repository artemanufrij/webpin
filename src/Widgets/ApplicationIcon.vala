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
    public class ApplicationIcon : Gtk.Overlay {

        Gtk.Image image;
        Gtk.Label label;
        Gtk.Box box;

        internal DesktopFile desktop_file { get; private set; }

        public signal void deleted (Gtk.Container? parent);
        public signal void edit_request (DesktopFile desktop_file);

        public ApplicationIcon (GLib.DesktopAppInfo app) {
            this.desktop_file = new DesktopFile.from_desktopappinfo (app);

            hexpand = false;
            vexpand = false;

            label = new Gtk.Label (this.desktop_file.name);

            set_icon (this.desktop_file.icon);

            this.margin = 6;
            this.margin_start = 20;
            this.margin_end = 20;

            var menu = new ActionMenu ();
            menu.halign = Gtk.Align.CENTER;
            menu.delete_clicked.connect (() => { remove_application (); });
            menu.edit_clicked.connect (() => { edit_request (desktop_file); });

            box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            box.pack_start (image, false, false, 0);
            box.pack_start (label, false, false, 0);
            box.pack_start (menu, false, false, 0);

            box.hexpand = false;
            box.vexpand = false;

            var event_box = new Gtk.EventBox ();
            event_box.add (box);
            event_box.events |= Gdk.EventMask.ENTER_NOTIFY_MASK|Gdk.EventMask.LEAVE_NOTIFY_MASK;

            event_box.enter_notify_event.connect ((event) => {
                menu.set_reveal_child (true);
                return false;
            });

            event_box.leave_notify_event.connect ((event) => {
                if (event.detail == Gdk.NotifyType.INFERIOR) {
                    return false;
                }
                menu.set_reveal_child (false);
                return false;
            });

            this.add (event_box);
        }

        public void set_new_desktopfile (DesktopFile desktop_file) {
            this.desktop_file = desktop_file;
            set_icon (this.desktop_file.icon);
        }

        private void set_icon (string icon) {
            if (File.new_for_path (icon).query_exists ()) {
                Gdk.Pixbuf pix = null;
                try {
                    pix = new Gdk.Pixbuf.from_file (icon);
                } catch (Error e) {
                    warning (e.message);
                }
                int new_height = 64;
                int new_width = 64;
                int margin_vertical = 0;
                int margin_horizontal = 0;

                if (pix.height > pix.width) {
                    new_width = new_width * pix.width / pix.height;
                    margin_horizontal = (new_height - new_width) / 2;
                } else if (pix.height < pix.width) {
                    new_height = new_height * pix.height / pix.width;
                    margin_vertical = (new_width - new_height) / 2;
                }
                if (image == null) {
                    image = new Gtk.Image.from_pixbuf (pix.scale_simple (new_width, new_height, Gdk.InterpType.BILINEAR));
                } else {
                    image.set_from_pixbuf (pix.scale_simple (new_width, new_height, Gdk.InterpType.BILINEAR));
                }

                image.margin_top = margin_vertical;
                image.margin_bottom = margin_vertical;
                image.margin_right = margin_horizontal;
                image.margin_left = margin_horizontal;
            } else {
                image = new Gtk.Image ();
                image.icon_name = icon;
                image.pixel_size = 64;
            }
        }

        private void remove_application () {
            desktop_file.delete_file ();
            deleted (this.get_parent());
            this.destroy ();
        }
    }

    public class ActionMenu : Gtk.Revealer {

        public signal void delete_clicked ();
        public signal void edit_clicked ();

        public ActionMenu () {
            var delete_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.BUTTON);
            delete_button.tooltip_text = _("Delete Webapp");
            delete_button.relief = Gtk.ReliefStyle.NONE;
            delete_button.clicked.connect (() => { delete_clicked (); });

            var edit_button = new Gtk.Button.from_icon_name ("edit-symbolic", Gtk.IconSize.BUTTON);
            edit_button.tooltip_text = _("Edit Webapp Properties");
            edit_button.relief = Gtk.ReliefStyle.NONE;
            edit_button.clicked.connect (() => { edit_clicked (); });

            var buttons = new Gtk.Grid ();
            buttons.orientation = Gtk.Orientation.HORIZONTAL;
            buttons.add (edit_button);
            buttons.add (delete_button);
            buttons.opacity = 0.5;

            this.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
            this.add (buttons);
        }
    }
}
