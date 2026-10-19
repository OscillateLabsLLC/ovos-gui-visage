"""Drive the face picker page (docs/face-palettes.html) in headless Chrome against a fake message bus.

The fake bus is a small websocket server on 127.0.0.1. It answers visage.face.get and visage.face.set with
visage.face.state, as the app does (lib/face/face_remote.dart), and it can stop answering. Chrome is driven over the
DevTools protocol: every key press and click goes into that headless browser only, never to the desktop.

usage: python3 -I tool/test_picker.py [--page PATH] [--screenshot PATH]
needs: Google Chrome or Chromium ($CHROME overrides the path) and websocket-client
"""

import argparse
import sys
import tempfile
import time
from pathlib import Path

# python3 -I leaves this script's directory off sys.path, and the picker_test package lives in it.
sys.path.insert(0, str(Path(__file__).resolve().parent))

from picker_test.checks import CHECKS, CheckFailed, Run  # noqa: E402
from picker_test.chrome import Chrome  # noqa: E402
from picker_test.fake_bus import FakeBus  # noqa: E402

PAGE = Path(__file__).resolve().parent.parent / "docs" / "face-palettes.html"


def run_checks(run):
    failed = 0
    for name, fn in CHECKS:
        start = time.monotonic()
        try:
            fn(run)
            print(f"PASS  {name} ({time.monotonic() - start:.1f} s)", flush=True)
        except (CheckFailed, RuntimeError) as err:
            failed += 1
            print(f"FAIL  {name}: {err}", flush=True)
    return failed


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--page", type=Path, default=PAGE, help="the page to test (default: docs/face-palettes.html)")
    parser.add_argument("--screenshot", help="save a PNG of the page after the Undo check")
    args = parser.parse_args()
    page = args.page.resolve()
    if not page.is_file():
        sys.exit(f"no page at {page}")
    start = time.monotonic()
    bus, chrome = FakeBus(), None
    scratch = tempfile.TemporaryDirectory(prefix="test-picker-", ignore_cleanup_errors=True)
    try:
        chrome = Chrome(Path(scratch.name))
        failed = run_checks(Run(chrome, bus, page, args.screenshot))
    finally:
        if chrome:
            chrome.close()
        bus.close()
        scratch.cleanup()
    print(f"{len(CHECKS) - failed} of {len(CHECKS)} checks passed in {time.monotonic() - start:.1f} s")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
