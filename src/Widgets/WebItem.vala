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

namespace Webpin.Widgets {
    public class WebItem : Gtk.FlowBoxChild {

        public string title {
            get {
                return desktop_file.name;
            }
        }

        Gtk.Image image;
        Gtk.Label label;

        internal DesktopFile desktop_file { get; private set; }

        public signal void deleted ();
        public signal void edit_request (DesktopFile desktop_file);

        public WebItem (GLib.DesktopAppInfo app) {
            this.desktop_file = new DesktopFile.from_desktopappinfo (app);
            build_ui ();
        }

        private void build_ui () {
            var content = new Gtk.Grid ();
            content.margin = 12;
            content.halign = Gtk.Align.CENTER;
            content.row_spacing = 6;

            image = new Gtk.Image ();
            label = new Gtk.Label (this.desktop_file.name);

            set_icon (this.desktop_file.icon);

            var menu = new ActionMenu ();
            menu.halign = Gtk.Align.CENTER;
            menu.delete_clicked.connect (() => { remove_application (); });
            menu.edit_clicked.connect (() => { edit_request (desktop_file); });

            content.attach (image, 0, 0);
            content.attach (label, 0, 1);
            content.attach (menu, 0, 2);

            var event_box = new Gtk.EventBox ();
            event_box.add (content);
            event_box.events |= Gdk.EventMask.ENTER_NOTIFY_MASK|Gdk.EventMask.LEAVE_NOTIFY_MASK;

            event_box.enter_notify_event.connect ((event) => {
                menu.opacity = 0.5;
                return false;
            });

            event_box.leave_notify_event.connect ((event) => {
                if (event.detail == Gdk.NotifyType.INFERIOR) {
                    return false;
                }
                menu.opacity = 0;
                return false;
            });

            this.add (event_box);
        }

        public void set_new_desktopfile (DesktopFile desktop_file) {
            this.desktop_file = desktop_file;
            set_icon (this.desktop_file.icon);
        }

        private void set_icon (string icon) {
            if (icon.has_prefix("/") && File.new_for_path (icon).query_exists ()) {
                Gdk.Pixbuf pix = null;
                try {
                    pix = new Gdk.Pixbuf.from_file (icon);
                } catch (Error e) {
                    warning (e.message);
                }
                pix = Services.DesktopFilesManager.align_and_scale_pixbuf (pix, 64);
                image.set_from_pixbuf (pix);
            } else {
                image.icon_name = icon;
                image.pixel_size = 64;
            }
        }

        private void remove_application () {
            desktop_file.delete_file ();
            deleted ();
            this.destroy ();
        }
    }

    public class ActionMenu : Gtk.Grid {

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

            this.add (edit_button);
            this.add (delete_button);
            this.opacity = 0;
        }
    }
}
