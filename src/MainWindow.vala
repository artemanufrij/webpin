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

namespace Webpin {
    public class MainWindow : Gtk.ApplicationWindow {
        Settings settings;

        Gtk.Stack stack;
        Gtk.HeaderBar headerbar;
        Gtk.Button back_button;
        Gtk.Button add_button;
        Gtk.MenuButton app_menu;

        Widgets.Views.Editor editor;
        Widgets.Views.WebItemsView web_items_view;

        construct {
            settings = Settings.get_default ();
            settings.notify["use-dark-theme"].connect (() => {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.use_dark_theme;
                if (settings.use_dark_theme) {
                    app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
                } else {
                    app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR));
                }
            });
        }

        public MainWindow () {
            build_ui ();
        }

        private void build_ui () {
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.use_dark_theme;
            set_default_size (700, 500);

            //headerbar
            headerbar = new Gtk.HeaderBar ();
            headerbar.show_close_button = true;
            headerbar.title = "Webpin";
            headerbar.get_style_context ().add_class ("default-decoration");
            set_titlebar (headerbar);

            back_button = new Gtk.Button.with_label (_("Applications"));
            back_button.get_style_context ().add_class ("back-button");
            back_button.valign = Gtk.Align.CENTER;
            headerbar.pack_start (back_button);

            add_button = new Gtk.Button ();
            add_button.image = new Gtk.Image.from_icon_name ("document-new", Gtk.IconSize.LARGE_TOOLBAR);
            add_button.tooltip_text = _("Add a new Web App");
            headerbar.pack_start (add_button);

            // SETTINGS MENU
            app_menu = new Gtk.MenuButton ();
            if (settings.use_dark_theme) {
                app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
            } else {
                app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR));
            }

            var settings_menu = new Gtk.Menu ();
            var menu_item_preferences = new Gtk.MenuItem.with_label (_("Preferences"));
            menu_item_preferences.activate.connect (() => {
                var preferences = new Dialogs.Preferences (this);
                preferences.run ();
            });

            settings_menu.append (menu_item_preferences);
            settings_menu.show_all ();

            app_menu.popup = settings_menu;
            headerbar.pack_end (app_menu);

            var welcome = new Granite.Widgets.Welcome (_("No Web Apps Available"), _("Manage your web apps."));
            welcome.append ("document-new", _("Create App"), _("Create a new web app with Webpin"));
            welcome.activated.connect ((index) => {
                switch (index) {
                    case 0:
                        show_assistant ();
                        break;
                }
            });

            web_items_view = new Widgets.Views.WebItemsView ();
            editor = new Widgets.Views.Editor ();
            stack = new Gtk.Stack ();
            stack.set_transition_duration (500);

            stack.add_named (welcome, "welcome");
            stack.add_named (web_items_view, "apps_view");
            stack.add_named (editor, "editor");

            add (stack);

            web_items_view.add_request.connect (() => {
                show_assistant ();
            });

            web_items_view.edit_request.connect ((desktop_file) => {
                show_assistant (desktop_file);
            });

            web_items_view.app_deleted.connect (() => {
                if (!web_items_view.has_items) {
                    show_welcome_view (Gtk.StackTransitionType.NONE);
                }
            });

            editor.application_created.connect ((new_file) => {
                web_items_view.add_web_item (new_file);
                web_items_view.select_last_item ();
                show_apps_view ();
            });

            editor.application_edited.connect ((edited_file) => {
                web_items_view.update_button (edited_file);
                show_apps_view ();
            });

            back_button.clicked.connect (() => {
                if (web_items_view.has_items) {
                    show_apps_view ();
                } else {
                    show_welcome_view ();
                }
            });

            add_button.clicked.connect (() => {
                show_assistant ();
            });

            delete_event.connect (() => {
                this.store_settings ();
                return false;
            });

            this.restore_settings ();
            show_all ();

            if (web_items_view.has_items) {
                show_apps_view (Gtk.StackTransitionType.NONE);
            } else {
                show_welcome_view (Gtk.StackTransitionType.NONE);
            }

            this.present ();
        }

        public void show_assistant (DesktopFile? desktop_file = null) {
            stack.set_transition_type (Gtk.StackTransitionType.SLIDE_LEFT);
            stack.set_visible_child_name("editor");
            back_button.show_all ();
            add_button.hide ();
            editor.edit_desktop_file (desktop_file);
        }

        private void show_apps_view (Gtk.StackTransitionType slide = Gtk.StackTransitionType.SLIDE_RIGHT) {
            stack.set_transition_type (slide);
            stack.set_visible_child_name ("apps_view");
            back_button.hide ();
            add_button.show_all ();
            editor.reset_fields ();
        }

        private void show_welcome_view (Gtk.StackTransitionType slide = Gtk.StackTransitionType.SLIDE_RIGHT) {
            stack.set_transition_type (slide);
            stack.set_visible_child_name ("welcome");
            back_button.hide ();
            add_button.hide ();
            editor.reset_fields ();
        }

        private void restore_settings () {
            this.set_default_size (settings.window_width, settings.window_height);

            if (settings.window_state == Settings.WindowState.MAXIMIZED) {
                this.maximize ();
            }
        }

        private void store_settings () {
            settings.window_state = (this.is_maximized ? Settings.WindowState.MAXIMIZED: Settings.WindowState.NORMAL);
            if (settings.window_state == Settings.WindowState.NORMAL) {
                settings.window_height = this.get_allocated_height ();
                settings.window_width = this.get_allocated_width ();
            }
        }
    }
}
