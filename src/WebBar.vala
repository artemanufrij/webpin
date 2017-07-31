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
    public class WebBar : Gtk.HeaderBar {

        public enum title_mode {
            TITLE,
            BROWSER;
        }

        UrlEntry url_entry;
        Gtk.Button share_button;
        Gtk.Button back_button;
        WebKit.WebView webview;

        public signal void back_event();

        public WebBar (WebKit.WebView webview) {

            this.get_style_context ().remove_class ("header-bar");
            this.webview = webview;

            url_entry = new UrlEntry();
            url_entry.show_all();

            share_button = new Gtk.Button.from_icon_name ("application-menu-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            share_button.margin_left = 15;
            share_button.show_all ();

            back_button = new Gtk.Button.from_icon_name ("go-next-symbolic-rtl", Gtk.IconSize.SMALL_TOOLBAR);
            back_button.margin_right = 15;
            back_button.show_all ();

            pack_start (back_button);
            pack_start (url_entry);
            pack_end (share_button);

            custom_title = new Gtk.Label(null);
            connect_signals ();
            show();
        }


       private void connect_signals () {
            webview.load_changed.connect ( (event) => {
                if (event == WebKit.LoadEvent.STARTED)
                    url_entry.set_text (webview.uri);
            });

            back_button.clicked.connect( () => { back_event(); });
            back_button.activate.connect( () => { back_event(); });
        }

        public void set_title_mode (title_mode mode) {

            if (mode == title_mode.TITLE) {
                custom_title = null;
                remove (share_button);
                remove (back_button);
                remove (url_entry);
                this.get_style_context ().remove_class ("header-bar");
            } else {
                pack_start (back_button);
                pack_start (url_entry);
                pack_end (share_button);
                custom_title = new Gtk.Label(null);
                this.get_style_context ().add_class ("header-bar");
            }
        }
    }
}
