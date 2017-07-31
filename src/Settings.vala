public class Settings : Granite.Services.Settings {

    private static Settings settings;
    public static Settings get_default () {
        if (settings == null)
            settings = new Settings ();

        return settings;
    }
    public int window_width { get; set; }
    public int window_height { get; set; }
    public WindowState window_state { get; set; }

    private Settings () {
        base ("org.pantheon.webby.SavedState");
    }

    public enum WindowState {
        NORMAL,
        MAXIMIZED,
        FULLSCREEN
    }
}
