"""Convert a GoXLR profile XML document into JSON.

The GoXLR profile format is a pure attribute tree: elements carry attributes
and child elements, never text. That maps onto an object where scalar values
are attributes and object (or list-of-object) values are child elements. The
root element's tag is dropped; the generator on the Nix side knows it
(ValueTreeRoot / MicProfileTree).

Integers are emitted as numbers; everything else (floats, hex colors, text)
stays a string so values round-trip byte-exact - float re-printing would mangle
them.
"""

import json
import re
import sys
import xml.etree.ElementTree as ET

INT = re.compile(r"^(0|-?[1-9][0-9]*)$")


def convert(elem, path):
    if elem.text and elem.text.strip():
        sys.exit(f"error: text content at {path} breaks the attribute-tree "
                 f"assumption: {elem.text.strip()[:50]!r}")

    out = {}
    for key, value in elem.attrib.items():
        if INT.match(value) and -(2**63) <= int(value) < 2**63:
            out[key] = int(value)
        else:
            out[key] = value

    children = {}
    for child in elem:
        children.setdefault(child.tag, []).append(
            convert(child, f"{path}/{child.tag}")
        )

    for tag, instances in children.items():
        if tag in out:
            sys.exit(f"error: attribute and child element both named "
                     f"{tag!r} at {path}")
        out[tag] = instances[0] if len(instances) == 1 else instances

    return out


def main():
    if len(sys.argv) != 2:
        sys.exit(f"usage: {sys.argv[0]} <profile.xml>")

    root = ET.parse(sys.argv[1]).getroot()
    print(json.dumps(convert(root, root.tag), indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
