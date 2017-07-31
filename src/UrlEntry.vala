public class UrlEntry : Gtk.Entry {


    public UrlEntry () {
        editable = false;
        set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "view-refresh-symbolic");
        set_icon_from_icon_name (Gtk.EntryIconPosition.PRIMARY, "text-html-symbolic");
    }

    public override void get_preferred_width (out int minimum_width, out int natural_width) {
        minimum_width = -1;
        natural_width = 3000;
    }

}
