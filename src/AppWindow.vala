public class AppWindow : Granite.Application {

    private Settings settings;

    public Gtk.Window mainwindow;

    private Gtk.Stack stack;
    private Gtk.HeaderBar headerbar;
    private Gtk.Button back_button;
    private Gtk.Button add_button;

    private WebbyAssistant assistant;
    private ApplicationsView apps_view;

    construct {
        program_name = "Webby";
        exec_name = "webby";

        app_years = "2015";
        app_icon = "webby";
        app_launcher = "webby.desktop";
        application_id = "net.launchpad.webby-browser";

        main_url = "https://code.launchpad.net/webby-browser";
        bug_url = "https://bugs.launchpad.net/webby-browser";
        help_url = "https://code.launchpad.net/webby-browser";
        translate_url = "https://translations.launchpad.net/webby-browser";

        about_authors = {"Erasmo Marín <erasmo.marin@gmail.com>",
                            "Artem Anufrij <artem.anufrij@live.de>"};
        about_documenters = {"Erasmo Marín",
                            "Artem Anufrij <artem.anufrij@live.de>"};
        about_artists = {"Erasmo Marín <erasmo.marin@gmail.com>",
                            "Artem Anufrij <artem.anufrij@live.de>"};
        about_comments = "Development release, not all features implemented";
        about_translators = "";
        about_license_type = Gtk.License.GPL_3_0;
    }

    public static AppWindow _instance = null;

        public static AppWindow instance {
            get {
                if (_instance == null)
                    _instance = new AppWindow ();
                return _instance;
            }
        }

    protected override void activate () {

        if (mainwindow != null) {
            mainwindow.present (); // present window if app is already running
            return;
        }

        settings = Settings.get_default ();

        mainwindow = new Gtk.Window ();

        mainwindow.set_default_size (700, 500);
        mainwindow.set_wmclass ("Webby", "Webby");

        //headerbar
        headerbar = new Gtk.HeaderBar ();
        headerbar.show_close_button = true;
        headerbar.title = "Webby";
        mainwindow.set_titlebar (headerbar);

        back_button = new Gtk.Button.with_label (_("Applications"));
        back_button.get_style_context ().add_class ("back-button");
        headerbar.pack_start (back_button);

        add_button = new Gtk.Button ();
        add_button.image = new Gtk.Image.from_icon_name ("add", Gtk.IconSize.LARGE_TOOLBAR);
        add_button.tooltip_text = _("Add a new Web App");
        headerbar.pack_start (add_button);

        var welcome = new Granite.Widgets.Welcome (_("No Web Apps Availible"), _("Create a new Webby Web App."));
        welcome.append ("add", _("Create App"), _("Create a new Webby web app."));
        welcome.activated.connect ((index) => {
            switch (index) {
                case 0:
                    show_assistant ();
                    break;
            }
        });

        apps_view = new ApplicationsView();
        assistant = new WebbyAssistant();
        stack = new Gtk.Stack ();
        stack.set_transition_duration (500);

        stack.add_named (welcome, "welcome");
        stack.add_named (apps_view, "apps_view");
        stack.add_named (assistant, "assistant");

        mainwindow.add (stack);

        apps_view.add_request.connect (() => {
            show_assistant ();
        });

        apps_view.edit_request.connect ((desktop_file) => {
            show_assistant (desktop_file);
        });

        apps_view.app_deleted.connect (() => {
            if (!apps_view.has_items) {
                show_welcome_view (Gtk.StackTransitionType.NONE);
            }
        });

        assistant.application_created.connect ((new_file) => {
            apps_view.add_button (new_file);
            apps_view.select_last_item ();
            show_apps_view ();
        });

        assistant.application_edited.connect ((edited_file) => {
            apps_view.update_button (edited_file);
            show_apps_view ();
        });

        back_button.clicked.connect (() => {
            if (apps_view.has_items)
                show_apps_view ();
            else
                show_welcome_view ();
        });

        add_button.clicked.connect (() => {
            show_assistant ();
        });

        mainwindow.delete_event.connect (() => {
            this.store_settings ();
            return false;
        });

        mainwindow.destroy.connect (Gtk.main_quit);

        this.restore_settings ();
        mainwindow.show_all ();

        if (apps_view.has_items)
            show_apps_view (Gtk.StackTransitionType.NONE);
        else
            show_welcome_view (Gtk.StackTransitionType.NONE);

        Gtk.main ();
    }

    private void show_assistant (DesktopFile? desktop_file = null) {
        stack.set_transition_type (Gtk.StackTransitionType.SLIDE_LEFT);
        stack.set_visible_child_name("assistant");
        back_button.show_all ();
        add_button.hide ();
        //fix ugly border at the bottom of headerbar
        mainwindow.queue_draw ();

        if (desktop_file != null)
            assistant.edit_desktop_file (desktop_file);
    }

    private void show_apps_view (Gtk.StackTransitionType slide = Gtk.StackTransitionType.SLIDE_RIGHT) {
        stack.set_transition_type (slide);
        stack.set_visible_child_name ("apps_view");
        back_button.hide ();
        add_button.show_all ();
        assistant.reset_fields ();
        //fix ugly border at the bottom of headerbar
        mainwindow.queue_draw ();
    }

    private void show_welcome_view (Gtk.StackTransitionType slide = Gtk.StackTransitionType.SLIDE_RIGHT) {
        stack.set_transition_type (slide);
        stack.set_visible_child_name ("welcome");
        back_button.hide ();
        add_button.hide ();
        assistant.reset_fields ();
        //fix ugly border at the bottom of headerbar
        mainwindow.queue_draw ();
    }

    private void restore_settings () {
        this.mainwindow.set_default_size (settings.window_width, settings.window_height);

        if (settings.window_state == Settings.WindowState.MAXIMIZED)
            this.mainwindow.maximize ();
    }

    private void store_settings () {
        settings.window_state = (this.mainwindow.is_maximized ? Settings.WindowState.MAXIMIZED: Settings.WindowState.NORMAL);
        if (settings.window_state == Settings.WindowState.NORMAL) {
            settings.window_height = this.mainwindow.get_allocated_height ();
            settings.window_width = this.mainwindow.get_allocated_width ();
        }
    }
}
