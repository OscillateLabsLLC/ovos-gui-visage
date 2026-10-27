# Changelog

## [2.5.0](https://github.com/OscillateLabsLLC/ovos-gui-visage/compare/v2.4.0...v2.5.0) (2026-10-27)


### Features

* **captions:** off by default; backlog a caption band ([b50a1c5](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/b50a1c5fef0b6d23644425230ee861d3494b4f3f))
* **diagnostics:** opt-in frame-timing log, VISAGE_FRAME_LOG=1 ([81edb11](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/81edb11fbb2badd76b9cc0507dbc36be3b3f0f4b))
* **diagnostics:** timestamps, move markers and a 120 Hz count ([4c79a90](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/4c79a90021d92ded5c37c01c0fa9452400fe47c2))
* **gui1:** backend-owned resting display with ambient weather ([e3f3a65](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/e3f3a65f97e561f0fa68eaf955cc9a19f76fb1a0))
* **gui1:** follow the proposed GUI-1 amendments (idle per session, client frames, companions) ([ed8e723](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/ed8e723548efbad750e63a33fe273abd0639fe8c))
* **gui1:** follow the remaining four §5.3 status topics ([528b2f0](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/528b2f0523419e4628da489ba670e64682fab435))
* **gui1:** honour idle only on an empty stack, tell gaps once, replay recorded fixtures ([d28e965](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/d28e9650e1a51fd60af81799e917e79c5fcea9f5))
* **gui1:** page entries from index and page_count; focus for steps and touches ([4d22ff1](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/4d22ff1420a0b7ae5e0deb78163e7b8d421039b9))
* **gui1:** put page events on the core bus as legacy ovos-gui forwarded them ([b471e3e](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/b471e3ede4ea588cf7039d68bd95557c6b0ace99))
* **gui1:** render SYSTEM_audio_player, SYSTEM_video_player and SYSTEM_media_player ([004fb6b](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/004fb6b24e28d257d1970f40c9f9b9da68e26bb6))
* **gui1:** render SYSTEM_clock from the device clock ([201856e](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/201856e19d70254ab7f0de056fdc2e3e03fef4fb))
* **gui1:** render SYSTEM_error, SYSTEM_list, SYSTEM_grid and SYSTEM_table ([09ea42e](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/09ea42ea67f992337f8afccdbed0a2eb3e917974))
* **gui1:** render SYSTEM_map as a label and coordinates card ([1296ae0](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/1296ae0a488e1a7639a7e8acfa3979291a736969))
* **gui1:** render SYSTEM_timer as one ring ticking from the device clock ([90bd0d0](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/90bd0d01a956a41b581e34fde524c765dd0ffa97))
* **gui1:** render SYSTEM_weather on the current-weather card ([0599e09](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/0599e09f365a37290667476aa750f50e220b8302))
* **gui1:** resting page reuses the homescreen chips, with the count badge ([db91e47](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/db91e47cfb9c6a76dbdf69f066aa4f56a25fc4db))
* **gui1:** show and report a dropped GUI-1 connection ([bb83be4](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/bb83be4e2a3f7c5bb2ca230e53200ccd7468ca87))
* **gui1:** SYSTEM_weather styles from condition_code and shows the forecast ([319f6be](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/319f6be211ab26a14a4ce8f48f510505e901dbf2))
* **menu:** redraw the in-window menu in Visage's vocabulary ([df25951](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/df259515d37655235ce8c28bd4b8a7d64ddc7fcb))
* **menu:** show the GUI protocol the connection speaks ([c2922b4](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/c2922b4630667368e408ff15521ba6bed9bce089))
* motion language, long-text paging and the polish audit, stacks on [#44](https://github.com/OscillateLabsLLC/ovos-gui-visage/issues/44) ([2d90da0](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/2d90da0c7b3749fbf8fde0577bd63b086112a6ff))
* **motion:** VISAGE_MOTION=cut makes every move a cut ([9034aa0](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/9034aa0872743687145ea32b8fce66318cddb94e))
* **pages:** a long text publishes its pages as an InnerPager ([35a735b](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/35a735ba8baccabef383c9d10995848fbe2faa00))
* **pages:** degrade the fallback page to the text or image page ([238da5b](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/238da5b4f82ee279a1d52d02de386e4e7dfd6a34))
* **pages:** existing hero glows bloom as their page arrives ([4544539](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/45445397041c10ee8e9201e57a8bf47d272e7f87))
* **pages:** hero glows and the item cadence on every stacked page ([dc52493](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/dc5249383e0fd2bb46da1163b9b3b64f29cd9e92))
* **pages:** honour reduced motion on the now-playing and busy views ([1bc7d8e](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/1bc7d8eecb3d8a54c1b33a703830d67d320546da))
* **protocol:** speak GUI-1 to ovos-gui-plugin-visage beside legacy ovos-gui ([3e33b1c](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/3e33b1ce2f819478cf6646847296a7ccd94d2f93))
* **resting:** the chips are born from one disc when the page appears ([d6ac19e](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/d6ac19e04a61d75bf57de2e044132cde31b8dded))
* **router:** accept OVOS-GUI-1 template names beside the legacy ones ([7928fa4](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/7928fa4bb7a750615ca8fd5015ef0a22ff950224))
* **shell:** gestures step a page's inner pages first; tap thirds ([43b46c2](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/43b46c20ebfc8f4ac2a3db5ea7da697a364a8851))
* **shell:** pages squash to a line or slide, through PageSwitch ([0d4c1b0](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/0d4c1b091b29325f11f8397ffcda302aac46942a))
* **shell:** the attention face collapses to a dot when it goes ([31cee54](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/31cee5489092b2ac147cf39a24ab4529bcc41a52))
* **sidecar:** proxy /gui1 to the GUI-1 adapter ([cca0f16](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/cca0f162ab96beb8658b92616a4371568d4993d8))
* speak OVOS-GUI-1 beside legacy ovos-gui, as its reference client ([ab5825c](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/ab5825cc9e1eb32f31fc6f645b127f29e2eca84d))
* **templates:** report a non-bool status success as a protocol fault ([bf5b3a4](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/bf5b3a42d85d2010719293eb1d2c141303635f8e))
* **templates:** status accepts the GUI-1 success flag ([f8c6abf](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/f8c6abf33abf2c22e9df9c2d0ae2ca8cd4e480e7))
* **widgets:** glow bloom and the campaign video's item cadence ([ddfb483](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/ddfb4831d58838cfe6d779c1d95e91a7f21e31cb))
* **window:** title the window with the protocol and the mode ([230963f](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/230963f8d56824125eee5fe0ce5aed87c232e74b))


### Bug Fixes

* **a11y:** fix the four text-contrast failures; the guard skips nothing ([a3ef614](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/a3ef6144bcce947d7dbff08a33fb85a8771c1d32))
* **clock:** a five-glyph time no longer meets the ring ([3f6dcb2](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/3f6dcb20ab0d4cb91f7d3214b3444957a7358cc2))
* **diagnostics:** stamp late frames at their vsync, moves on the same clock ([4f22bbd](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/4f22bbdf3ffbe5b8bc0c91e0bf0aadcf15ea97c1))
* **face:** cancel a running blink or widen when the controller is disposed ([932a2d6](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/932a2d6e7dff0529690713bd651f24867eeb1bc4))
* **face:** hold a still frame under reduced motion; the audit lists are empty ([81d3177](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/81d3177b91dbd89b861dd71eefeb3af5e4926ef4))
* **face:** read the audio-out §5.4 viseme shape, unknown codes at rest ([66e75bc](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/66e75bcc852b2c4a4af58db1ca528e5017196d58))
* **faults:** print every reported fault in debug builds too ([a85edf8](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/a85edf816e9a8b4892341c2a39ede03d37fd3d0f))
* **gui1:** announce a page again when it returns after the screen emptied ([2b3239f](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/2b3239f0d9d69515b66762f61ef4d4867639c7fd))
* **gui1:** finger-sized view buttons, a shorter video line, brief checks in tests ([76184ea](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/76184eaff4a1fd3063164aa8563ed56a31b5f850))
* **gui1:** hold the expired timer ring still under reduced motion ([0bf022a](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/0bf022a868b17e69aa4e7c31e073bcdf35c4d5c6))
* **gui1:** play glyph on the video still, -1 position is unknown, cite the spec by link ([d4932e1](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/d4932e198807a5c6e7b0437e4f5f5a3f7bcfbcf0))
* **gui1:** the merged template pages meet the design guards ([325d56c](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/325d56cd60226052aba289777a8c5f03f1b6f847))
* **idle:** report an unreadable homescreen temperature, never show 0 ([81e9d4c](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/81e9d4c6eaff387113760bb91d379fe50d96e68e))
* **loading:** the thinking dots hold still under reduced motion ([125ffb5](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/125ffb5ae1435d71590893c30e5b7f04c8e46064))
* **notifications:** the badge always opens the list; an empty store says so ([e7c6300](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/e7c6300356fe0d69cfe51f4e2f3ba8c0a204e843))
* **notifications:** the resting screen on GUI-1 keeps the list open ([e5f0921](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/e5f092196c1156ef124ba73a18052bcf29eed58f))
* **pages:** report a SYSTEM_text without its required text ([b3ac0b7](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/b3ac0b7f62dd9e2d36033cce50c487ba20d08ed5))
* **release:** release-please bumps the GUI-1 client version constant with pubspec ([263f012](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/263f01287217569834f88f893b18cbeca4343c1f))
* **release:** release-please bumps the GUI-1 client version constant with pubspec ([1f0c172](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/1f0c1725bb27922183eb76df3fea400521da3811))
* **resting:** device hour format, ambient weather ages out, night icon ([89768a8](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/89768a88e7ef344c4bf6f5618bd95eaea3efa01b))
* **shell:** cap the page expand's overshoot at about 2.3 percent ([d61c32f](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/d61c32f04cd30e70079828e31dcf2387c7664cd7))
* **shell:** centre the resting chips, full-size window, upright captions ([9281e59](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/9281e59913a71e857ba12afd213b96e26f5ccff8))
* **widgets:** Glow, Ring, StaggerEnter and RiseIn honour reduced motion ([b4f9426](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/b4f942612e096ae9a2c27ce9586ecf62ad44df0f))


### Performance Improvements

* **shell:** a page move scales a snapshot, never a live page ([4ca345b](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/4ca345bbd31990dbb4d9a9170be0176c974e5f75))
* **shell:** no opacity layer over a page at rest ([fa8d9a9](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/fa8d9a933fb8c51bfcbb742e70fdf6a41278ad22))
* **widgets:** the glow is a radial gradient, not an animated blur ([b9e6893](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/b9e6893c4c708cd1883cc54b9b4f90ed1964d1a3))

## [2.4.0](https://github.com/OscillateLabsLLC/ovos-gui-visage/compare/v2.3.0...v2.4.0) (2026-10-24)


### Features

* **notifications:** stored notification list ([dc6ba4d](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/dc6ba4dc71b0fad94b3ac7704f72fb2030df6561))
* **notifications:** stored notification list ([7ba3cbf](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/7ba3cbfeccde0471b937f137eb166111a67184ae))
* **volume:** on-screen volume display and volume controls over the bus ([aab2923](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/aab2923bf70ee55981f982aaac7129ff6abbf033))
* **volume:** on-screen volume display and volume controls over the bus ([97b9d3c](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/97b9d3cb12cdad9c5d76b0be15b12b19d7c03607))

## [2.3.0](https://github.com/OscillateLabsLLC/ovos-gui-visage/compare/v2.2.0...v2.3.0) (2026-10-24)


### Features

* **linux:** .deb packages for amd64 and arm64 on each release ([7be0b35](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/7be0b359c2f746b4dfa3abf34e54010021316dc0))
* **linux:** package the release bundle as a .deb ([2e91611](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/2e91611750d18ecc0a49c5636ec55d868c018eb7)), closes [#17](https://github.com/OscillateLabsLLC/ovos-gui-visage/issues/17)
* **linux:** point the kiosk autostart at the packaged app ([7a961a2](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/7a961a28f036bb415a32629aa72886fca4a95179)), closes [#17](https://github.com/OscillateLabsLLC/ovos-gui-visage/issues/17)


### Bug Fixes

* **ci:** read the glibc version without breaking the pipe ([6316049](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/6316049019548779789ad5b89d7ebb52e3971816))

## [2.2.0](https://github.com/OscillateLabsLLC/ovos-gui-visage/compare/v2.1.0...v2.2.0) (2026-10-24)


### Features

* **alerts:** cancel timers, snooze and cancel alarms ([55e5848](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/55e5848528c44e100cd660c5995d8c7abad183ee))
* **notifications:** close popups and run their actions ([04ba45d](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/04ba45d062f91a278321728c029791a826b6d26f))
* **ocp:** transport, seek and tap-to-play on the OCP pages ([817332b](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/817332b4e72d9836cc309e130ad34caa8c1d7a80))
* **pages:** answer SYSTEM_InputBox ([ff24dbd](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/ff24dbd604343a6f3765528efc06ffcade9dfa72))
* **protocol:** let pages send events back to OVOS ([9269b2c](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/9269b2c3420e61547a87a52d8860de4de466b6b9))
* swipe between a skill's pages and report page use ([4a20f1c](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/4a20f1c547271b9e16d0ec1678fa278c5bf15725))
* touch and pointer input, part A (foundation) ([3a94ea9](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/3a94ea93ccd13b7531310cff99450a4970e7e9f7))
* touch and pointer input, part B (skill controls), stacks on [#36](https://github.com/OscillateLabsLLC/ovos-gui-visage/issues/36) ([9eaae03](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/9eaae03b898e09ab007b18925c1e4c5c3370bd29))
* type a command ([bec29e1](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/bec29e1dbae445dcf1705ebc0840d4e2795fe07d))
* **window:** open the menu inside the window ([9f37a27](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/9f37a27be3b2559409bd17591261bc010f5241a6)), closes [#14](https://github.com/OscillateLabsLLC/ovos-gui-visage/issues/14)


### Bug Fixes

* **window:** close the in-window menu on a click outside it ([794f3af](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/794f3af498bce5e9786b6baf95d96d53f5075f09))
* **window:** open the in-window menu once the peek badge has expanded ([1477e32](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/1477e32bc84fe94098d907eb27ff2a6c0156c7f5))

## [2.1.0](https://github.com/OscillateLabsLLC/ovos-gui-visage/compare/v2.0.0...v2.1.0) (2026-10-23)


### Features

* captions, turn outcome and notification popups ([92bd22c](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/92bd22c4144ed30bf77cd0623a2d4e4ac05512a2))
* pop up skill notifications, display-only ([8c4304d](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/8c4304d1aac4f71b6b541cd31dd702f008b8bb0a))
* show a brief success, failure or cancelled outcome per turn ([f0a84c2](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/f0a84c2a353a7bca616329b9974af0881abb8e50))
* show captions of the heard utterance and the spoken reply ([7974662](https://github.com/OscillateLabsLLC/ovos-gui-visage/commit/7974662e1677deaf28b1f11230d3da5c7ca72626))

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
