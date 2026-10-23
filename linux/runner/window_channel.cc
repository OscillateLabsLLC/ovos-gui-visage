#include "window_channel.h"

#include <gtk/gtk.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif
#ifdef GDK_WINDOWING_WAYLAND
#include <gdk/gdkwayland.h>
#endif

#include <cstring>

static const char* kChannelName = "ovos_gui_visage/window";
static const char* kDisplayBackendMethod = "displayBackend";

static const char* display_backend() {
  GdkDisplay* display = gdk_display_get_default();
#ifdef GDK_WINDOWING_X11
  if (GDK_IS_X11_DISPLAY(display)) return "x11";
#endif
#ifdef GDK_WINDOWING_WAYLAND
  if (GDK_IS_WAYLAND_DISPLAY(display)) return "wayland";
#endif
  return "other";
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* call, gpointer user_data) {
  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(fl_method_call_get_name(call), kDisplayBackendMethod) == 0) {
    g_autoptr(FlValue) result = fl_value_new_string(display_backend());
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(call, response, &error)) {
    g_warning("Could not answer %s on %s: %s", fl_method_call_get_name(call), kChannelName, error->message);
  }
}

FlMethodChannel* window_channel_new(FlView* view) {
  FlBinaryMessenger* messenger = fl_engine_get_binary_messenger(fl_view_get_engine(view));
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(messenger, kChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb, nullptr, nullptr);
  return channel;
}
