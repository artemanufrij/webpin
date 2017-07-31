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
