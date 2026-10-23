# Changelog

## [2.0.0](https://github.com/OscillateLabsLLC/ovos-gui-visage/compare/v1.1.0...v2.0.0) (2026-10-23)


### ⚠ BREAKING CHANGES

* **linux:** the desktop file and icon names change. Nothing has shipped on Linux yet, so no one is affected; a checkout that ran just linux-install before this change should run just linux-uninstall first, then install again.

### Features

* keep the display awake in kiosk mode on Linux ([f7e4685](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/f7e4685cc7eec7c55f55fdfef584ac2b086051c6))
* keep the display awake in kiosk mode on Linux ([ecd0a36](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/ecd0a36fbc32ca5d502724f960b543a7c65bd075)), closes [#15](https://github.com/OscillateLabsLLC/ovos-gui-visage/issues/15)
* **linux:** add a desktop entry and a per-user install recipe ([c40f979](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/c40f9793ecc88cd2565fdf7c735c1640aadee922))
* **linux:** app icon, desktop entry and optional kiosk autostart ([0152d66](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/0152d666a08526f6a39bb0f925c184203809d2ce))
* **linux:** generate hicolor app icons from the face badge ([0916fe8](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/0916fe8a5d91eac0a878cbd9593ef092eedcf0a5))
* **linux:** make native Wayland honest about the widget modes ([6e23025](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/6e23025d475ec42b2902417d01d1b0b339668afd))
* **linux:** optional kiosk start on login through XDG autostart ([55fa607](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/55fa607ade0553400be800811e686183e69981e5))
* **linux:** prefer X11 through Xwayland in the runner ([c1adcba](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/c1adcba1aefe1de51328aabe378745c0fea4e54c))
* **linux:** prefer X11 through Xwayland, make native Wayland honest, detect a missing tray ([7f3b570](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/7f3b570d817fed58737efcbf44983255ab604ddf))
* **linux:** report a session bus with no tray watcher ([bc127bd](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/bc127bdcb7334fb93837aad10931f8a3c379a7e2)), closes [#14](https://github.com/OscillateLabsLLC/ovos-gui-visage/issues/14)
* **linux:** the application id matches the macOS bundle id ([8357791](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/83577913dbb4384e68240901f5180e9069d26580))
* **linux:** title the window OVOS Visage and give it the app icon ([8dd192a](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/8dd192aa4e84762cf786b875bb0996b97a8c9450))


### Bug Fixes

* **faults:** print each fault's context in release builds ([8a06777](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/8a06777af875194dcfe884b0ac5c137d594ff61e))
* leaving kiosk on Linux no longer flashes the window in the middle ([f175752](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/f17575281fc858a173005b88e2db57f20bcf7817))
* leaving kiosk on Linux no longer flashes the window in the middle ([0279e61](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/0279e612f6ea7248c885c405bf3267eb8c16be39)), closes [#16](https://github.com/OscillateLabsLLC/ovos-gui-visage/issues/16)
* **window:** the Quit item names the app as OVOS Visage ([0e46db7](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/0e46db7ef7cb7a179ef915078f83c46454ee7bde))

## [1.1.0](https://github.com/OscillateLabsLLC/ovos-gui-visage/compare/v1.0.1...v1.1.0) (2026-10-19)


### Features

* publish the web build's container image to ghcr.io on each release ([8ca5cbe](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/8ca5cbe4249225cf080bfa78f652f00ba50af494))
* publish the web build's container image to ghcr.io on each release ([18736ca](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/18736ca47656787293f3bdea0845b1d2e963683c))


### Bug Fixes

* the picker test retries Chrome's DevTools probe when a read times out ([2bc128a](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/2bc128adc09d69ebf9bdf0d9d08077b6038ba106))
* the picker test retries Chrome's DevTools probe when a read times out ([a7bc2ed](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/a7bc2edf475da8ac0a4a03a791761cfe7a0a1c3e))
* the sidecar reaches OVOS on Linux, and the README gets a user quick start ([b82109b](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/b82109b98e48c1794b2f83e3df111c8cded53c49))
* the sidecar reaches OVOS on Linux, and the README gets a user quick start ([9a42329](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/9a42329efb7a9633dcb92db378f8dfea989c9416))
* the web build's tab title and icons are OVOS Visage, not the Flutter template ([826881b](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/826881b140659a30890fd58c8f16430364c89a60))
* the web build's tab title and icons are OVOS Visage, not the Flutter template ([8998c2a](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/8998c2aa10b7549123a5175b071283945c4c530d))

## [1.0.1](https://github.com/OscillateLabsLLC/ovos-gui-visage/compare/v1.0.0...v1.0.1) (2026-10-19)


### Bug Fixes

* face picker tests pass on Linux ([72492df](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/72492df4310e7c35c7799485198cc7ce6759103d))
* the macOS app icon is the visage badge instead of the Flutter logo ([ce0f09a](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/ce0f09adc3b6f0a54c629a5a1142c8abdf1b19dc))
* the macOS app icon is the visage badge instead of the Flutter logo ([dcd592a](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/dcd592aa172a9151c511b93c6be33888bb7346a3))

## 1.0.0 (2026-10-19)


### Features

* a Colour row on the picker page, sent and followed over the bus ([7a170d0](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/7a170d0c73fbf5735b8433916b5140f9b9100dc6))
* a colours field on the face, by name or by tokens, over the bus ([48efda8](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/48efda8ced1081d01fdc1a3c5e7a304056beabfb))
* a Face picker… menu item and visage.face.picker ([7f58aa4](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/7f58aa47e19e1e2c331a95dee5a59dc75459a03e))
* a status menu built from the app's state and sent to the runner ([a42c8b9](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/a42c8b921be0d02f60eccbfecb77303a12a08faf))
* alerts pages: timer rings, alarm chips and grid, list view ([d5bd0be](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/d5bd0be87fa7482b47b3ba46a821a3f2b43fda96))
* alerts view models with the ported node tests ([ba6781d](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/ba6781dde48110ee5412262ccd009487d9cfa7b9))
* attention state machine and OVOS Lottie playback from the cache ([ea36203](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/ea36203ab59cb39a31fe359dccb7e8a5ab1144a9))
* core bus and GUI socket clients, verified against live ovos-gui ([d4788b5](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/d4788b5d2a22a9e504b19655380d345fd8522483))
* date-time time and date pages ([1625920](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/1625920765c613bc8ea5b7292392a1e0f67c2b1d))
* desktop and floating widget modes pinned to a screen corner ([485fbad](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/485fbad1a76dc5af3dde396662e2d02cdb72fee2))
* face widget with swappable eye and mouth painters ([edefade](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/edefade2de469c24eea99a45362192dda031d93a))
* homescreen idle page ([4da0c6e](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/4da0c6ee98380b6f78ec2d0e3613a5e1e215dd16))
* **linux:** RGBA window visual so widget modes float their frame ([1f19c7d](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/1f19c7dc9c5d28448b8e1dc09a46786b055f584c))
* **macos:** a menu bar item, runtime window levels and visibility ([3192b6f](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/3192b6fd0cbbea3029f11709cc11563c89e2e4fe))
* **macos:** kiosk level, Dock and menu bar hiding, and keep-awake in the runner ([3b23035](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/3b23035ee543826f7ef732167a42766e0753268e))
* **macos:** openUrl on the window channel ([79dccd1](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/79dccd1113f1800a5d8b2a994fbfa621764a9023))
* OCP now-playing and browse view models with the ported node tests ([d8d1a2e](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/d8d1a2e731999e728949007947390cc71737c222))
* OCP pages: now playing, busy, suggestions and home ([08d03fd](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/08d03fdc9433b7ae11953e972d1dffd75ded57a6))
* page router with blank and fallback pages, theme tokens and shared circle widgets ([dc1c974](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/dc1c974d3e81ef5c276eeb06ebf2e2b559bd98c2))
* peek and peekSize in the window config ([0ecf962](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/0ecf96236e6b6aa609de0a30e0d9a7bfc6705992))
* peek mode, the widget idles as a badge and grows while OVOS has attention ([87cfb29](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/87cfb29534bc235a79828ef82cf5a64dd79d7567))
* peek timing, expand on attention and collapse after a hold ([35d522a](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/35d522ae18b935e053a882971d12bef4ce259782))
* per-part icon motion from the SVG keyframes ([53cad15](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/53cad158b0c9c96d99dd85f0aa2f10ab833b5aa5))
* **picker:** read the bus from #bus= as well as ?bus= ([e8ad2e8](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/e8ad2e8d53781b17b65abe9e9b168ace1d3009f7))
* **picker:** rebuild the face picker around preset cards ([976a77d](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/976a77d32834a561ea1d07382197f5b21574f7dc))
* **picker:** rebuild the face picker around preset cards ([bef75d0](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/bef75d0faa731c3e990cac705858ffb4ab6f669f))
* scaffold ovos-gui-visage with the GUI state model and fixture parity tests ([275903a](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/275903ab8c47217e1833cf76bbe34fb667f3f337))
* spike app shell on macOS with the attention overlay and Lottie strip ([5e9fcd7](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/5e9fcd7cbcb6158a9a0e203fecb757beb3ea2ed3))
* switch the face while running, over the bus and by hand on the screen ([8d0d678](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/8d0d678318c224aae9fb3d2c43386d0bd4d6bd6a))
* SYSTEM templates: face, text frame, loading, status, image, input box; url and html placeholders ([1f80b44](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/1f80b44f34056081f45b04c45850897d3464df6a))
* template view models; time page splits a trailing AM/PM ([a51a828](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/a51a82869e7f6153c3fd8c829e4c912329468c08))
* the desktop widget is the default mode ([eacca00](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/eacca004667d936cb319433c346f2173fc8d3dc8))
* the Mark 1 face as a second theme, chosen by config ([3736da6](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/3736da6d683d581413ec0ec069d493326bd1189c))
* the picker page drives the device over the bus; docs and screenshots ([94775fe](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/94775feaa9c9b579fa023f9ee8bd7b2b650cd885))
* visage.window.* on the bus, and the widget window resizes in its corner ([989420b](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/989420b1d51860954d4d6713b4fe7a1b3b225e14))
* viseme shapes, timeline and tweening with the ported node tests ([eee8a66](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/eee8a6659a347b4af607c223583bac37a9e60667))
* visible and mode in visage.window.set, applied to the native window ([e243265](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/e24326599cda144a902b02f3e954d00a4551808e))
* weather pages: current, single day, daily and hourly forecast, sunrise and sunset ([cd87db5](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/cd87db585eb408073947c278f7cf7f00f472e44c))
* web build with a dart:io-free resource layer and per-platform socket endpoints ([688cb9a](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/688cb9a0e3c45e9cb2f936d2fc9661c4e71a51c1))
* web views for SYSTEM_UrlFrame and SYSTEM_HtmlFrame where the platform has one ([fc19e9f](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/fc19e9f59bfa462414d61fa631ac58ebe6027cb8))
* WidgetManager port with the recorded-bus tests, spike screenshots ([6463dac](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/6463dac617b8857ac686c149c8da393f01419635))
* **window:** drag a widget to another corner, and a tray item on Linux ([9c1a035](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/9c1a035a17491a0f2641f915bea9e4eebc2e9f6a))
* **window:** drag a widget to another corner, and a tray item on Linux ([9a1ab2c](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/9a1ab2cdd20d6cfe5da67b446ec56c16997c7fa9))
* **window:** fullscreen kiosk mode ([af9a693](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/af9a693c28d44dc499f40df7747476f445b1e6c2))
* **window:** fullscreen kiosk mode ([a07eeba](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/a07eeba9f4247fc345972587ace60fc7aa28d7da))


### Bug Fixes

* a stream with no declared duration takes mpv's steady length as its total ([248d68d](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/248d68df7b89f11c80e82ad1455a769f10740c8c))
* bell swings at rest and shakes when ringing; idle badge no longer clipped ([e88f230](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/e88f23086b4663978e1f10415d2262675fd01b38))
* **face:** leave the preset's own colourway out of a face's log name ([fd0ece7](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/fd0ece782ecbf2761b7308586cef278d211ae12a))
* **face:** make the Mark 1 face legible as the 96 px peek badge ([1f95fba](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/1f95fba84b3b32d5c5bd0e0ce2fe163eb826b206))
* **face:** make the Mark 1 face legible as the peek badge ([2cc3e83](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/2cc3e83bca7aa9832182b006d3aacedddc078173))
* **linux:** Hide face and Face picker work from the tray ([35d26c0](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/35d26c08c706e84a1395d9c4609828f6131520f8))
* **linux:** the tray tooltip is optional, since the Linux plugin lacks it ([f0826f3](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/f0826f3bec1d9849c3872fb2a1804b9744345ea2))
* **linux:** tray item through the app indicator, with the badge as its icon ([5035e7b](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/5035e7b0ed2937005efefb54986f6caa4c23b0e9))
* no opacity layer over a lone blurred shadow, which Impeller cannot inherit opacity into ([0ac2fa1](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/0ac2fa161996861b75e426630f6950826533d7d4))
* **picker:** give the launcher page the picker page's title ([2891383](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/289138367b6eb7c4b337d51e5e4e785f7130b3c4))
* **picker:** open a launcher page so the #bus fragment survives ([ca6b56d](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/ca6b56dd73b2a12811ef6f50691610ee3bc9dbcb))
* report every fault the display survives instead of swallowing it ([6bcb390](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/6bcb390dfea3f56be701da77217177f8b38558cb))
* the idle weather icon animates like the weather pages ([5a74ec1](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/5a74ec1f4e705dc02857115236f8dd6bce55dd7c))
* try-on mode holds a peeking window open and leaves when it collapses ([78f59f1](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/78f59f1d1202ea61720cb4ee0ab3d7f7657c61ab))
* weather numbers from a comma-decimal locale ([4ab0794](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/4ab079490624cff1eb16de3a02e92691a9ccc256))
* **window:** keep the Linux widget resizable so GTK honours its size ([aa55d5a](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/aa55d5abe71e0aa232cb8a02fc74cb683d799da4))
* **window:** leave kiosk with one resize, after the Dock comes back ([37c0ba5](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/37c0ba5d63a888217b5186cfba2d56beca08342e))
* **window:** Linux kiosk uses the window manager's fullscreen state ([8d774b9](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/8d774b9f89221e731b6b5842823343ef2e894040))
* **window:** place and show the widget on Linux when a plugin call is missing ([688fcd5](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/688fcd5852a00fff8c1394c9b7e3dad7e95e0372))
* **window:** shrink before moving a Linux widget so the corner holds ([9da771c](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/9da771c38988aeb1592ef01d0aa50b4adaaae4d4))
* **window:** wait for the Linux resize before moving, and keep kiosk resizable ([1d6211e](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/1d6211efa5cf5cfae87e0e5fe10c574186803f4e))
* **window:** widget modes on Linux, measured on Kubuntu 24.04 ([eed0b7a](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/eed0b7a070094a905639bd131c6d3f16aa562483))
