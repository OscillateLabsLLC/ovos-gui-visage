#ifndef RUNNER_WINDOW_CHANNEL_H_
#define RUNNER_WINDOW_CHANNEL_H_

#include <flutter_linux/flutter_linux.h>

// The runner's own channel, ovos_gui_visage/window (lib/window/window_channel.dart). On Linux it answers
// displayBackend with the GDK backend in use: "x11", "wayland" or "other". Every other method is not implemented.
FlMethodChannel* window_channel_new(FlView* view);

#endif  // RUNNER_WINDOW_CHANNEL_H_
