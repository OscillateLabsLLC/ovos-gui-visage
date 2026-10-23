#include <gtk/gtk.h>

#include "my_application.h"

int main(int argc, char** argv) {
  // The corner widgets need an X11 window: native Wayland lets no app place or stack its own window. Xwayland is
  // preferred when it is there, and native Wayland is the fallback. GDK_BACKEND still overrides this.
  gdk_set_allowed_backends("x11,wayland");
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
