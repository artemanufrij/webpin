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
    public class WebItemsView : Gtk.Box {

        public signal void add_request ();
        public signal void edit_request (DesktopFile desktop_file);
        public signal void app_deleted ();

        Gtk.FlowBox web_items;

        public bool has_items { get { return web_items.get_children ().length () > 0; } }

        public WebItemsView () {

            GLib.Object (orientation: Gtk.Orientation.VERTICAL);
            var scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;

            web_items = new Gtk.FlowBox();
            web_items.set_sort_func (sort_func);
            web_items.valign = Gtk.Align.START;
            web_items.vexpand = false;
            web_items.homogeneous = true;
            web_items.column_spacing = 12;
            web_items.row_spacing = 12;
            web_items.margin = 24;
            web_items.child_activated.connect ((child) => {
                if (child is WebItem) {
                    var app_icon = child as WebItem;
                    try {
                        Process.spawn_command_line_async ("com.github.artemanufrij.webpin " + app_icon.desktop_file.url.replace("%%", "%"));
                    } catch (SpawnError err) {
                        warning (err.message);
                    }
                }
            });
            load_applications ();

            scrolled.add (web_items);
            this.pack_start (scrolled, true, true, 0);
        }

        public void load_applications () {
            var applications = Services.DesktopFilesManager.get_webpin_applications ();

            foreach (GLib.DesktopAppInfo app in applications.values) {
                this.add_web_item (app);
            }
        }

        public void add_web_item (GLib.DesktopAppInfo app) {
            var web_item = new WebItem (app);
            web_item.edit_request.connect ((desktop_file) => {
                edit_request (desktop_file);
                web_items.unselect_all ();
            });
            web_item.deleted.connect (() => {
                app_deleted ();
            });
            web_items.add (web_item);
            web_items.show_all ();
        }

        public void select_last_item () {
            web_items.select_child (web_items.get_child_at_index ((int)web_items.get_children ().length () - 1));
        }

        public void select_first_item () {
            web_items.select_child (web_items.get_child_at_index (0));
        }

        public void update_button (GLib.DesktopAppInfo app) {
            foreach (var item in web_items.get_children ()) {
                if (item is WebItem) {
                    var app_icon = item as WebItem;

                    if (app_icon.desktop_file.name == app.get_display_name ()) {
                        app_icon.set_new_desktopfile (new DesktopFile.from_desktopappinfo (app));
                        web_items.select_child (item as Gtk.FlowBoxChild);
                        break;
                    }
                }
            }
        }

        public int sort_func (Gtk.FlowBoxChild child1, Gtk.FlowBoxChild child2) {
            var item1 = (WebItem)child1;
            var item2 = (WebItem)child2;

            return item1.title.collate (item2.title);
        }
    }
}
