"""The checks the runner runs against the picker page, in order, and the steps they share."""

import json
import time

from .chrome import HELPERS
from .fake_bus import SET, START


class CheckFailed(Exception):
    pass


def expect(ok, message):
    if not ok:
        raise CheckFailed(message)


class Run:
    """What every check gets: the browser, the bus, and the steps they share."""

    def __init__(self, chrome, bus, page, screenshot):
        self.chrome, self.bus, self.page, self.screenshot = chrome, bus, page, screenshot

    def load(self, *flags, bus=True):
        """Opens the page fresh, with the bus in the hash unless bus=False, and waits until it is ready."""
        hash_parts = ([f"bus=ws://127.0.0.1:{self.bus.port}/core"] if bus else []) + list(flags)
        url = self.page.as_uri() + ("#" + "&".join(hash_parts) if hash_parts else "")
        self.chrome.js("if (location.protocol === 'file:') localStorage.clear(); window.__old = true")
        self.bus.reset()
        self.chrome.call("Page.navigate", url="about:blank")
        self.chrome.call("Page.navigate", url=url)
        ready = "!window.__old && location.protocol === 'file:' && document.readyState === 'complete'"
        self.wait(ready + " && document.querySelectorAll('#cards .card').length > 0", True, "the page to load")
        self.chrome.js(HELPERS)
        if bus:
            self.wait("document.getElementById('status').dataset.state", "live", "the page to connect to the bus")
            self.wait("__t.checked('cards')", START, "the page to show the face the bus announced")

    def wait(self, expression, want, what, timeout=3.0):
        deadline = time.monotonic() + timeout
        while (got := self.chrome.js(expression)) != want:
            if time.monotonic() > deadline:
                raise CheckFailed(f"waited {timeout:g} s for {what}: wanted {want!r}, got {got!r}")
            time.sleep(0.05)

    def wait_sets(self, want, timeout=3.0):
        deadline = time.monotonic() + timeout
        while (got := self.bus.messages(SET)) != want:
            if time.monotonic() > deadline:
                raise CheckFailed(f"the page sent {SET} {got}, wanted {want}")
            time.sleep(0.05)

    def tab_to(self, group):
        for _ in range(40):
            self.chrome.press("Tab")
            if self.focus().startswith(group + "/"):
                return
        raise CheckFailed(f"40 presses of Tab did not reach the {group} group; focus is on {self.focus()}")

    def focus(self):
        return self.chrome.js("__t.focus()")

    def checked(self, group):
        return self.chrome.js(f"__t.checked('{group}')")

    def moving(self, selector):
        """True if the canvas changes over half a second."""
        before = self.chrome.js(f"__t.pixels({json.dumps(selector)})")
        time.sleep(0.5)
        return self.chrome.js(f"__t.pixels({json.dumps(selector)})") != before

    def no_sets(self):
        time.sleep(0.3)
        expect(self.bus.messages(SET) == [], f"the page sent {SET} {self.bus.messages(SET)}")


CHECKS = []


def check(name):
    def register(fn):
        CHECKS.append((name, fn))
        return fn

    return register


def card(name):
    return f'#cards [aria-labelledby="title-{name}"]'


@check("arrow keys move focus between the cards and do not apply")
def arrows_on_cards(t):
    t.load()
    t.tab_to("cards")
    expect(t.focus() == "cards/hybrid", f"Tab reached {t.focus()}, not the current face")
    seen = []
    for key in ("ArrowRight", "ArrowRight", "ArrowLeft", "ArrowUp"):
        t.chrome.press(key)
        seen.append(t.focus())
    expect(seen == ["cards/camera", "cards/pod", "cards/camera", "cards/hybrid"], f"focus went {seen}")
    t.no_sets()
    expect(t.checked("cards") == "hybrid", f"the checked card changed to {t.checked('cards')}")


@check("arrow keys move focus within an option group and do not apply")
def arrows_on_options(t):
    t.load("customise")
    t.tab_to("eyes")
    expect(t.focus() == "eyes/Round", f"Tab reached {t.focus()}, not the current eyes")
    seen = []
    for key in ("ArrowRight", "ArrowDown", "ArrowLeft"):
        t.chrome.press(key)
        seen.append(t.focus())
    expect(seen == ["eyes/LED ring", "eyes/Square", "eyes/LED ring"], f"focus went {seen}")
    t.no_sets()
    expect(t.checked("eyes") == "Round", f"the checked eyes changed to {t.checked('eyes')}")


@check("Space or Enter applies the focused card or option")
def keys_apply(t):
    t.load("customise")
    t.tab_to("cards")
    t.chrome.press("ArrowRight")
    t.chrome.press(" ")
    t.wait("__t.checked('cards')", "camera", "Space to apply the Camera card")
    t.wait_sets([{"preset": "camera"}])
    t.wait("__t.checked('eyes')", "Camera", "the eyes group to follow the Camera face")
    t.tab_to("eyes")
    t.chrome.press("ArrowRight")
    t.chrome.press("Enter")
    t.wait("__t.checked('eyes')", "One lens", "Enter to apply the One lens eyes")
    t.wait_sets([{"preset": "camera"}, {"eyes": "mono", "mouth": "grille", "mouthSize": "regular", "colours": "visage"}])


@check("a tap applies a card")
def tap_applies(t):
    t.load()
    t.chrome.click(card("robot"))
    t.wait("__t.checked('cards')", "robot", "the tap to apply the Robot card")
    t.wait_sets([{"preset": "robot"}])


@check('"Saved" shows after the assistant answers with visage.face.state')
def saved(t):
    t.load()
    t.chrome.click(card("camera"))
    t.wait("__t.saved()", "ok:Saved.", '"Saved."', timeout=2)


@check('"Not saved" shows 4 s after a change the assistant does not answer')
def not_saved(t):
    t.load()
    with t.bus.lock:
        t.bus.answering = False
    t.chrome.click(card("pod"))
    start, seen = time.monotonic(), set()
    while "did not answer" not in (text := t.chrome.js("__t.saved()")):
        seen.add(text)
        expect(time.monotonic() - start < 6, f"no warning 6 s after the change; the message was {seen}")
        time.sleep(0.05)
    elapsed = time.monotonic() - start
    expect(3.8 <= elapsed <= 5, f"the warning came after {elapsed:.1f} s, not 4 s")
    expect(text == "warn:Not saved. Your assistant did not answer.", f"the warning was {text!r}")
    expect(not any("Saved." in s and "Not" not in s for s in seen), f'"Saved." showed with no answer: {seen}')


@check('"Changed on this page only" shows with no bus')
def no_bus(t):
    t.load(bus=False)
    status = t.chrome.js("document.getElementById('status').textContent")
    expect(status.startswith("Preview only."), f"the status line said {status!r}")
    t.chrome.click(card("robot"))
    t.wait("__t.saved()", "ok:Changed on this page only.", '"Changed on this page only."')
    expect(t.checked("cards") == "robot", f"the checked card is {t.checked('cards')}")
    expect(t.bus.received == [], f"the bus got {t.bus.received}")


@check("Undo puts back the face before the last change, and only that one")
def undo(t):
    t.load()
    t.chrome.click(card("robot"))
    t.wait("__t.saved()", "ok:Saved.", '"Saved." for Robot')
    t.chrome.click(card("pod"))
    t.wait_sets([{"preset": "robot"}, {"preset": "pod"}])
    t.wait("__t.checked('cards')", "pod", "the Pod card")
    t.chrome.click("#undo")
    t.wait("__t.checked('cards')", "robot", "Undo to put back Robot")
    back = {"eyes": "block", "mouth": "solid", "mouthSize": "regular", "colours": "visage", "backdrop": "none"}
    t.wait_sets([{"preset": "robot"}, {"preset": "pod"}, back])
    expect(t.chrome.js("document.getElementById('undo').hidden"), "Undo is still offered after one use")
    if t.screenshot:
        t.chrome.screenshot(t.screenshot)


@check("#customise opens the Customise section")
def hash_customise(t):
    t.load("customise")
    expect(t.chrome.js("document.getElementById('customise').open"), "Customise is closed")
    expect(t.chrome.js("document.getElementById('all').hidden"), "every combination is shown too")


@check("#all opens every combination")
def hash_all(t):
    t.load("all")
    expect(not t.chrome.js("document.getElementById('all').hidden"), "every combination is hidden")
    expect(t.chrome.js("document.getElementById('showAll').getAttribute('aria-expanded')") == "true", "aria-expanded is not true")
    expect(t.chrome.js("document.querySelectorAll('#grid .cell').length") == 72, "the grid does not have 72 cells")
    expect(not t.chrome.js("document.getElementById('customise').open"), "Customise is open too")


@check("with normal motion, the preview and the focused cell move")
def motion_normal(t):
    t.load("customise", "all")
    t.chrome.js("document.querySelector('#grid .cell').focus()")
    expect(t.moving("#preview"), "the preview is still")
    expect(t.moving("#grid .cell canvas"), "the focused cell is still")
    expect(not t.moving(card("hybrid") + " canvas"), "a card moves")


@check("with prefers-reduced-motion: reduce, only the selected face moves")
def motion_reduced(t):
    t.chrome.call("Emulation.setEmulatedMedia", features=[{"name": "prefers-reduced-motion", "value": "reduce"}])
    try:
        t.load("customise", "all")
        expect(t.chrome.js("matchMedia('(prefers-reduced-motion: reduce)').matches"), "the emulation did not apply")
        t.chrome.js("document.querySelector('#grid .cell').focus()")
        expect(not t.moving("#preview"), "the Talking preview moves; it should be one still open mouth")
        t.chrome.click("#views [role=radio]", "Listening")
        t.chrome.js("document.querySelector('#grid .cell').focus()")
        expect(t.moving("#preview"), "the Listening preview of the selected face is still")
        expect(not t.moving("#grid .cell canvas"), "the focused cell moves")
        expect(not t.moving(card("hybrid") + " canvas"), "a card moves")
    finally:
        t.chrome.call("Emulation.setEmulatedMedia", features=[])


@check("no script errors on the page or bad frames on the bus")
def no_errors(t):
    expect(t.chrome.errors == [], f"the page threw {t.chrome.errors}")
    expect(t.bus.faults == [], f"the fake bus saw {t.bus.faults}")
