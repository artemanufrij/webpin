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
    public class InfoDialog : Gtk.Dialog {
        public InfoDialog (string title, string label, string icon_name) {

            this.title = title;
            set_default_size (350, 100);

            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
            box.pack_start (new Gtk.Image.from_icon_name(icon_name, Gtk.IconSize.DIALOG), false, false, 0);
            box.pack_start (new Gtk.Label (label), true, false, 0);
            box.margin = 15;

            Gtk.Box content = get_content_area () as Gtk.Box;
            content.pack_start (box, true, true, 0);

            add_button (_("Accept"), Gtk.ResponseType.ACCEPT);
        }
    }
}
