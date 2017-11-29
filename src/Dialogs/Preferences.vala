/*-
 * Copyright (c) 2017 Artem Anufrij <artem.anufrij@live.de>
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

namespace Webpin.Dialogs {
    public class Preferences : Gtk.Dialog {
        Webpin.Settings settings;

        construct {
            settings = Webpin.Settings.get_default ();
        }

        public Preferences (Gtk.Window parent) {
            Object (
                transient_for: parent
            );
            build_ui ();

            this.response.connect ((source, response_id) => {
                switch (response_id) {
                    case Gtk.ResponseType.CLOSE:
                        destroy ();
                    break;
                }
            });
        }

        private void build_ui () {
            this.resizable = false;
            var content = get_content_area () as Gtk.Box;

            var grid = new Gtk.Grid ();
            grid.column_spacing = 12;
            grid.row_spacing = 12;
            grid.margin = 12;

            var use_dark_theme_label = new Gtk.Label (_("Use Dark Theme"));
            use_dark_theme_label.halign = Gtk.Align.START;
            var use_dark_theme = new Gtk.Switch ();
            use_dark_theme.active = settings.use_dark_theme;
            use_dark_theme.notify["active"].connect (() => {
                settings.use_dark_theme = use_dark_theme.active;
            });

            grid.attach (use_dark_theme_label, 0, 0);
            grid.attach (use_dark_theme, 1, 0);

            content.pack_start (grid, false, false, 0);

            this.add_button (_("_Close"), Gtk.ResponseType.CLOSE);
            this.show_all ();
        }
    }
}
