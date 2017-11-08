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
    public class ApplicationsView : Gtk.Box {

        public signal void add_request();
        public signal void edit_request(DesktopFile desktop_file);
        public signal void app_deleted ();

        private Gtk.FlowBox icon_view;
        private Gee.HashMap<string, GLib.DesktopAppInfo> applications;

        public bool has_items { get { return icon_view.get_children ().length () > 0; } }

        public ApplicationsView () {

            GLib.Object (orientation: Gtk.Orientation.VERTICAL);
            var scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;

            icon_view = new Gtk.FlowBox();
            icon_view.valign = Gtk.Align.START;
            icon_view.vexpand = false;
            icon_view.homogeneous = true;
            icon_view.column_spacing = 24;
            icon_view.row_spacing = 24;
            icon_view.margin = 24;
            icon_view.child_activated.connect ((child) => {
                if ((child as Gtk.FlowBoxChild).get_child () is ApplicationIcon) {
                    var app_icon = (child as Gtk.FlowBoxChild).get_child () as ApplicationIcon;
                    try {
                        Process.spawn_command_line_async ("com.github.artemanufrij.webpin " + app_icon.desktop_file.url.replace("%%", "%"));
                    } catch (SpawnError e) {
                        debug ("Error: %s\n", e.message);
                    }
                }
            });
            load_applications ();

            scrolled.add(icon_view);
            this.pack_start(scrolled, true, true, 0);

        }

        public void load_applications () {
            applications = DesktopFile.get_webpin_applications();

            foreach (GLib.DesktopAppInfo app in applications.values) {
                this.add_button (app);
            }
        }

        public void add_button (GLib.DesktopAppInfo app) {
            var image = new ApplicationIcon (app);
            image.edit_request.connect ((desktop_file) => {
                edit_request (desktop_file);
                icon_view.unselect_all ();
            });
            image.deleted.connect ((parent) => {
                this.icon_view.remove (parent);
                app_deleted ();
            });
            icon_view.add (image);
            icon_view.show_all ();
        }

        public void select_last_item () {
            icon_view.select_child (icon_view.get_child_at_index ((int)icon_view.get_children ().length () - 1));
        }

        public void select_first_item () {
            icon_view.select_child (icon_view.get_child_at_index (0));
        }

        public void update_button (GLib.DesktopAppInfo app) {
            foreach (var item in icon_view.get_children ()) {
                if ((item as Gtk.FlowBoxChild).get_child () is ApplicationIcon) {
                    var app_icon = (item as Gtk.FlowBoxChild).get_child () as ApplicationIcon;

                    if (app_icon.desktop_file.name == app.get_display_name ()) {
                        app_icon.set_new_desktopfile (new DesktopFile.from_desktopappinfo (app));
                        icon_view.select_child (item as Gtk.FlowBoxChild);
                        break;
                    }
                }
            }
        }
    }
}
