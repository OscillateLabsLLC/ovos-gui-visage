#!/usr/bin/env python3
"""Split the animated icon SVGs into z-ordered layers for Flutter.

Flutter's SVG renderer runs no CSS keyframes, so each icon in assets/icon_sources/ becomes a stack of layer files
in assets/icons/ that share the viewBox: a layer per element that carried an animated class (its ancestors kept
for inherited stroke, fill and clip-path, its siblings removed) and a layer per run of static elements between
them, in document order. lib/widgets/icon_layers.g.dart lists the stack per icon; lib/widgets/icon_motion.dart
gives each animated layer its motion, copied from the stylesheet the splitter strips.

Stdlib only. Run from the repo root: python3 tool/split_icons.py
"""

import copy
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCES = ROOT / "assets" / "icon_sources"
OUT = ROOT / "assets" / "icons"
MANIFEST = ROOT / "lib" / "widgets" / "icon_layers.g.dart"
SVG_NS = "http://www.w3.org/2000/svg"
XLINK_NS = "http://www.w3.org/1999/xlink"
ET.register_namespace("", SVG_NS)
ET.register_namespace("xlink", XLINK_NS)


def tag(element: ET.Element) -> str:
    return element.tag.split("}")[-1]


def animated_classes(style_text: str) -> set[str]:
    """Class names whose rule sets an animation (`.drop { animation: ... }`, not `.drop:nth-of-type(2)`)."""
    classes = set()
    for selectors, body in re.findall(r"([^{}]+)\{([^{}]*)\}", style_text):
        if "animation" not in body or "@keyframes" in selectors:
            continue
        for selector in selectors.split(","):
            match = re.fullmatch(r"\s*\.([A-Za-z0-9_-]+)\s*", selector)
            if match:
                classes.add(match.group(1))
    return classes


def strip_style(root: ET.Element) -> str:
    text = ""
    for child in list(root):
        if tag(child) == "style":
            text += child.text or ""
            root.remove(child)
    return text


def parents_of(root: ET.Element) -> dict[ET.Element, ET.Element]:
    return {child: parent for parent in root.iter() for child in parent}


def is_animated(element: ET.Element, classes: set[str]) -> str | None:
    """The animated class of the element, when one of its classes is animated."""
    for cls in (element.get("class") or "").split():
        if cls in classes:
            return cls
    return None


def layer_with(root: ET.Element, keep: set[ET.Element]) -> ET.Element:
    """A copy of root holding only defs and the elements in `keep` (ancestors, the target, its subtree)."""
    parents = parents_of(root)
    index = {element: i for i, element in enumerate(root.iter())}
    kept = {index[element] for element in keep}
    clone = copy.deepcopy(root)
    for element, i in zip(clone.iter(), range(len(index))):
        pass
    clone_elements = list(clone.iter())
    originals = list(root.iter())
    for original, cloned in zip(originals, clone_elements):
        if tag(original) == "defs" or original is root:
            continue
        inside_defs = any(tag(parent) == "defs" for parent in ancestors(original, parents))
        if inside_defs or index[original] in kept:
            continue
        parent_clone = clone_elements[index[parents[original]]]
        if cloned in list(parent_clone):
            parent_clone.remove(cloned)
    return clone


def ancestors(element: ET.Element, parents: dict) -> list[ET.Element]:
    chain = []
    while element in parents:
        element = parents[element]
        chain.append(element)
    return chain


def subtree(element: ET.Element) -> set[ET.Element]:
    return set(element.iter())


def split(source: Path) -> list[dict]:
    tree = ET.parse(source)
    root = tree.getroot()
    classes = animated_classes(strip_style(root))
    parents = parents_of(root)
    targets = [element for element in root.iter() if element is not root and is_animated(element, classes)]
    counts: dict[str, int] = {}
    layers = []
    name = source.stem
    static_run: set[ET.Element] = set()
    run_index = 0

    def flush_static():
        nonlocal static_run, run_index
        if not static_run:
            return
        file = f"{name}__s{run_index}.svg"
        write(layer_with(root, static_run), OUT / file)
        layers.append({"asset": file, "cls": None, "nth": 0})
        run_index += 1
        static_run = set()

    for element in root.iter():
        if element is root or tag(element) == "defs" or any(tag(p) == "defs" for p in ancestors(element, parents)):
            continue
        if element in targets:
            flush_static()
            cls = is_animated(element, classes)
            counts[cls] = counts.get(cls, 0) + 1
            file = f"{name}__{cls}_{counts[cls]}.svg"
            write(layer_with(root, set(ancestors(element, parents)) | subtree(element)), OUT / file)
            layers.append({"asset": file, "cls": cls, "nth": counts[cls]})
        elif not any(ancestor in targets for ancestor in ancestors(element, parents)):
            static_run |= set(ancestors(element, parents)) | {element}
    flush_static()
    if not targets:
        write(root, OUT / f"{name}.svg")
        return [{"asset": f"{name}.svg", "cls": None, "nth": 0}]
    return layers


def write(element: ET.Element, path: Path) -> None:
    for node in element.iter():
        node.attrib.pop("class", None)
    ET.ElementTree(element).write(path, encoding="unicode", xml_declaration=False)
    path.write_text(path.read_text() + "\n")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for stale in OUT.glob("*.svg"):
        stale.unlink()
    manifest = {}
    for source in sorted(SOURCES.glob("*.svg")):
        manifest[source.stem] = split(source)
        print(f"{source.stem}: {[layer['asset'] for layer in manifest[source.stem]]}")
    lines = [
        "// GENERATED by tool/split_icons.py from assets/icon_sources/; do not edit.",
        "// Each icon is a stack of layer assets in draw order; `cls` names the animated class a layer carried.",
        "",
        "class IconLayer {",
        "  const IconLayer(this.asset, {this.cls, this.nth = 0});",
        "",
        "  final String asset;",
        "  final String? cls;",
        "  final int nth;",
        "}",
        "",
        "const iconLayers = <String, List<IconLayer>>{",
    ]
    for name, layers in manifest.items():
        entries = ", ".join(
            f"IconLayer('{l['asset']}'" + (f", cls: '{l['cls']}', nth: {l['nth']})" if l["cls"] else ")") for l in layers
        )
        lines.append(f"  '{name}': [{entries}],")
    lines += ["};", ""]
    MANIFEST.write_text("\n".join(lines))
    print(f"wrote {MANIFEST.relative_to(ROOT)}")


if __name__ == "__main__":
    sys.exit(main())
