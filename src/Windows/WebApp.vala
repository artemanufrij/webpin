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

namespace Webpin.Windows {
    public class WebApp : Gtk.Window {
        Gdk.WindowState current_state;

        Gtk.HeaderBar headerbar;
        Gtk.Button button_back;
        Gtk.Button button_forward;
        Widgets.Browser browser;
        Gtk.Spinner spinner;

        public DesktopFile desktop_file { get; private set; }

        public WebApp (DesktopFile desktop_file) {
            this.desktop_file = desktop_file;
            this.set_wmclass (desktop_file.url, desktop_file.url);
            this.events |= Gdk.EventMask.STRUCTURE_MASK;

            var color = desktop_file.color;
            if (color != null) {
                set_color (color);
            }
            browser = new Widgets.Browser (desktop_file);

            headerbar = new Gtk.HeaderBar ();
            headerbar.title = desktop_file.name;
            headerbar.show_close_button = true;
            headerbar.get_style_context ().add_class ("default-decoration");

            if (desktop_file.view_mode == "default") {
                header_build_copy_button ();
                header_build_pin_button ();
            }

            spinner = new Gtk.Spinner ();
            spinner.tooltip_text = _("Loading…");
            spinner.set_size_request (16, 16);
            headerbar.pack_end (spinner);

            if (desktop_file.view_mode == "default") {
                header_build_navi_buttons ();
            }

            this.set_titlebar (headerbar);

            this.delete_event.connect (() => {
                save_settings ();
                if (desktop_file.hide_on_close) {
                    this.hide_on_delete ();
                }
                return desktop_file.hide_on_close;
            });

            this.window_state_event.connect ((event) => {
                current_state = event.new_window_state;
                return false;
            });

            browser.external_request.connect ((action) => {
                try {
                    Process.spawn_command_line_async ("xdg-open " + action.get_request ().uri);
                } catch (Error e) {
                    warning (e.message);
                }
            });

            browser.desktop_notification.connect ((title, body, icon) => {
                var desktop_notification = new Notification (title);
                desktop_notification.set_body (body);
                desktop_notification.set_icon (icon);
                desktop_notification.add_button_with_target_value (_ ("Open %s").printf (desktop_file.name), "app.open-web-app", new GLib.Variant.string (desktop_file.url));
                WebpinApp.instance.send_notification (null, desktop_notification);
            });

            browser.request_begin.connect (() => {
                spinner.active = true;
            });

            browser.request_finished.connect (() => {
                spinner.active = false;
                if (button_back != null) {
                    button_back.sensitive = browser.can_go_back ();
                    button_forward.sensitive = browser.can_go_forward ();
                }
            });

            browser.found_website_color.connect ((color) => {
                stdout.printf ("found website color: %s\n", color.to_string ());
                int gray_val = (int)(desktop_file.color.red * 255);
                if (desktop_file.color == null || ((gray_val == 222 || gray_val == 255) && desktop_file.color.red == desktop_file.color.green && desktop_file.color.red == desktop_file.color.blue)) {
                    set_color (color);
                    desktop_file.color = color;
                }
            });

            this.add (browser);

            load_settings ();

            this.show_all ();

            this.show.connect (() => {
                var x = desktop_file.get_property ("X-Webpin-WindowX");
                var y = desktop_file.get_property ("X-Webpin-WindowY");
                if (x != null && y != null) {
                    this.move (int.parse (x), int.parse (y));
                }
            });
        }

        private void header_build_navi_buttons () {
            button_back = new Gtk.Button.from_icon_name ("go-previous-symbolic", Gtk.IconSize.MENU);
            button_back.tooltip_text = _("Back");
            button_back.sensitive = false;
            button_back.valign = Gtk.Align.CENTER;
            button_back.clicked.connect (() => {
                browser.go_back ();
            });
            headerbar.pack_start (button_back);

            var button_home = new Gtk.Button.from_icon_name ("go-home-symbolic", Gtk.IconSize.MENU);
            button_home.tooltip_text = _("Home");
            button_home.valign = Gtk.Align.CENTER;
            button_home.clicked.connect (() => {
                browser.go_home ();
            });
            headerbar.pack_start (button_home);

            button_forward = new Gtk.Button.from_icon_name ("go-next-symbolic", Gtk.IconSize.MENU);
            button_forward.tooltip_text = _("Forward");
            button_forward.sensitive = false;
            button_forward.valign = Gtk.Align.CENTER;
            button_forward.clicked.connect (() => {
                browser.go_forward ();
            });
            headerbar.pack_start (button_forward);

            var button_refresh = new Gtk.Button.from_icon_name ("view-refresh-symbolic", Gtk.IconSize.MENU);
            button_refresh.tooltip_text = _("Reload");
            button_refresh.valign = Gtk.Align.CENTER;
            button_refresh.clicked.connect (() => {
                browser.reload ();
            });
            headerbar.pack_start (button_refresh);
        }

        private void header_build_copy_button () {
            var copy_url = new Gtk.Button.from_icon_name ("insert-link-symbolic", Gtk.IconSize.MENU);
            copy_url.valign = Gtk.Align.CENTER;
            copy_url.tooltip_text = _ ("Copy URL into clipboard");
            copy_url.clicked.connect (() => {
                Gtk.Clipboard.get_default (Gdk.Display.get_default ()).set_text (browser.web_view.uri, -1);
            });
            headerbar.pack_end (copy_url);
        }

        private void header_build_pin_button () {
            var stay_open = new Gtk.ToggleButton ();
            stay_open.valign = Gtk.Align.CENTER;
            stay_open.active = desktop_file.hide_on_close;
            stay_open.tooltip_text = _ ("Run in background if closed");
            stay_open.image = new Gtk.Image.from_icon_name ("view-pin-symbolic", Gtk.IconSize.MENU);
            stay_open.toggled.connect (() => {
                desktop_file.edit_property ("X-Webpin-StayOpen", stay_open.active.to_string ());
                desktop_file.save_to_file ();
            });
            headerbar.pack_end (stay_open);
        }

        private void set_color (Gdk.RGBA color) {
            var mid = color.red + color.blue + color.green;
            color.alpha = 1;
            if (mid / 3 < 0.5) {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
            }
            Granite.Widgets.Utils.set_color_primary (this, color);
        }

        public void toggle_fullscreen () {
            if (current_state.to_string () == Gdk.WindowState.FULLSCREEN.to_string ()) {
                this.unfullscreen ();
            } else {
                this.fullscreen ();
            }
        }

        private void load_settings () {
            var width = desktop_file.info.get_string ("X-Webpin-WindowWidth");
            var height = desktop_file.info.get_string ("X-Webpin-WindowHeight");
            var x = desktop_file.info.get_string ("X-Webpin-WindowX");
            var y = desktop_file.info.get_string ("X-Webpin-WindowY");
            var state = desktop_file.info.get_string ("X-Webpin-WindowMaximized");
            var zoom = desktop_file.info.get_string ("X-Webpin-WindowZoom");

            if (width != null && height != null) {
                set_default_size (int.parse (width), int.parse (height));
            } else {
                set_default_size (1000, 600);
            }

            if (x != null && y != null) {
                this.move (int.parse (x), int.parse (y));
            } else {
                this.window_position = Gtk.WindowPosition.CENTER;
            }

            if (state != null && state == "max") {
                this.maximize ();
            }

            if (zoom != null) {
                browser.web_view.zoom_level = double.parse (zoom);
            }
        }

        private void save_settings () {
            if (this.is_maximized) {
                desktop_file.edit_property ("X-Webpin-WindowMaximized", "max");
            } else {
                int x, y;
                this.get_position (out x, out y);

                int width, height;
                this.get_size (out width, out height);

                desktop_file.edit_property ("X-Webpin-WindowX", x.to_string ());
                desktop_file.edit_property ("X-Webpin-WindowY", y.to_string ());
                desktop_file.edit_property ("X-Webpin-WindowWidth", width.to_string ());
                desktop_file.edit_property ("X-Webpin-WindowHeight", height.to_string ());
                desktop_file.edit_property ("X-Webpin-WindowMaximized", "norm");
            }
        }

        public override bool key_press_event (Gdk.EventKey event) {
            switch (event.keyval) {
            case Gdk.Key.Escape :
                unfullscreen ();
                break;
            case Gdk.Key.F11 :
                toggle_fullscreen ();
                break;
            case Gdk.Key.KP_Add :
            case Gdk.Key.plus :
                if (Gdk.ModifierType.CONTROL_MASK in event.state) {
                    browser.web_view.zoom_level += 0.1;
                    desktop_file.edit_property ("X-Webpin-WindowZoom", browser.web_view.zoom_level.to_string ());
                    return true;
                }
                break;
            case Gdk.Key.KP_Subtract :
            case Gdk.Key.minus :
                if (Gdk.ModifierType.CONTROL_MASK in event.state) {
                    browser.web_view.zoom_level -= 0.1;
                    desktop_file.edit_property ("X-Webpin-WindowZoom", browser.web_view.zoom_level.to_string ());
                    return true;
                }
                break;
            case Gdk.Key.KP_0 :
            case Gdk.Key.@0 :
                if (Gdk.ModifierType.CONTROL_MASK in event.state) {
                    browser.web_view.zoom_level = 1;
                    desktop_file.edit_property ("X-Webpin-WindowZoom", browser.web_view.zoom_level.to_string ());
                    return true;
                }
                break;
            case Gdk.Key.F5 :
                if (Gdk.ModifierType.CONTROL_MASK in event.state) {
                    browser.reload ();
                } else {
                    browser.reload_bypass_cache ();
                }
                return true;
            case Gdk.Key.Left :
                if (Gdk.ModifierType.MOD1_MASK in event.state) {
                    browser.web_view.go_back ();
                    return true;
                }
                break;
            case Gdk.Key.Right :
                if (Gdk.ModifierType.MOD1_MASK in event.state) {
                    browser.web_view.go_forward ();
                    return true;
                }
                break;
            }

            return (base.key_press_event != null) ? base.key_press_event (event) : true;
        }
    }
}
