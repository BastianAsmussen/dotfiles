#!/usr/bin/env python3
"""Render and (optionally) push an Icotera i4850-20 config backup.

The NixOS `router` module renders a "plan" JSON from typed options and hands it
to this script. The plan fully describes the parameter database; this script
turns it into the exact on-wire backup format the GETOUI web panel accepts:

    backup = gzip( tar( db.bin, db.bin_md5, db.bin_checksum ) )

    db.bin          1024-byte firmware header + N records, each
                    <key>\\0 <len:u8> <type:u8> <value[len]>
    db.bin_md5      ascii md5 hex of db.bin (no newline)
    db.bin_checksum opaque fixed firmware descriptor, reproduced verbatim

Value encodings are fully determined by the declared record length and are the
result of reverse-engineering a real backup (round-trips byte-for-byte):

    u8        1 byte   little unsigned
    u16be     2 bytes  big-endian unsigned (NAT port numbers)
    ipv4      4 bytes  one dotted-quad
    ipv4pair  8 bytes  two dotted-quads (primary/secondary DNS)
    str       N bytes  ASCII, NUL-terminated, zero-padded to N

Secrets (admin password, WiFi passphrase) are never part of the plan; the plan
only carries their file paths and this script reads them at run time.

Subcommands:
    generate <plan.json> <out.bin>   build the backup, no network access
    push     <plan.json>             build in a temp dir, then log in and upload
"""

import base64
import gzip
import hashlib
import http.cookiejar
import io
import json
import os
import sys
import tarfile
import urllib.error
import urllib.parse
import urllib.request

UPLOAD_FIELD = "upload_config_file_req"

# The firmware routes the file-only upload by the session's current page, not by
# a request id, so the session must "open" the customer-config page first.
CONFIG_PAGE = "SETTINGS/CUSTOMERCONFIG"

# Upload response `msg` codes (from the web UI): 1 = applied, 2 = nothing to
# change (the config already matches). Everything else is a failure.
UPLOAD_OK = {
    "1": "config uploaded",
    "2": "already matches the device (nothing to change)",
}


def encode_value(kind, length, value):
    """Encode a decoded value into its fixed-width firmware representation."""
    if kind == "u8":
        v = int(value)
        if not 0 <= v <= 0xFF:
            raise ValueError(f"u8 out of range: {v}")
        return bytes([v])
    if kind == "u16be":
        v = int(value)
        if not 0 <= v <= 0xFFFF:
            raise ValueError(f"u16 out of range: {v}")
        return v.to_bytes(2, "big")
    if kind == "ipv4":
        return encode_ipv4(value)
    if kind == "ipv4pair":
        if len(value) != 2:
            raise ValueError(f"ipv4pair needs two addresses: {value!r}")
        return encode_ipv4(value[0]) + encode_ipv4(value[1])
    if kind == "str":
        # The firmware stores single-byte (latin-1 / iso-8859-1) strings; that
        # is the codec the byte-exact round-trip was proven against.
        try:
            raw = str(value).encode("latin-1")
        except UnicodeEncodeError as exc:
            raise ValueError(
                f"value {value!r} has characters outside the device's "
                "latin-1 range; restrict it to ASCII/iso-8859-1"
            ) from exc
        # Leave room for at least one NUL terminator, matching the firmware.
        if len(raw) > length - 1:
            raise ValueError(
                f"string {value!r} does not fit in {length} bytes (with NUL)"
            )
        return raw + b"\x00" * (length - len(raw))
    raise ValueError(f"unknown kind: {kind}")


def encode_ipv4(text):
    octets = str(text).split(".")
    if len(octets) != 4:
        raise ValueError(f"not an IPv4 address: {text!r}")
    return bytes(int(o) for o in octets)


def read_secret(path):
    """Read a secret file, stripping trailing newline bytes if present.

    Strips both CR and LF so a secret stored with a CRLF ending or a stray
    blank line does not bake a control byte into the password/passphrase field.
    """
    with open(path, "rb") as fh:
        data = fh.read()
    return data.rstrip(b"\r\n").decode("latin-1")


def build_db_bin(plan):
    out = bytearray(base64.b64decode(plan["header_b64"]))
    for rec in plan["records"]:
        if "secretFile" in rec:
            value = read_secret(rec["secretFile"])
        else:
            value = rec["value"]
        encoded = encode_value(rec["kind"], rec["len"], value)
        if len(encoded) != rec["len"]:
            raise ValueError(
                f"{rec['key']}: encoded {len(encoded)} bytes, expected {rec['len']}"
            )
        out += rec["key"].encode("latin-1")
        out += b"\x00"
        out += bytes([rec["len"], rec["type"]])
        out += encoded
    return bytes(out)


def build_backup(plan):
    """Return the gzip(tar(...)) backup blob for the given plan."""
    db_bin = build_db_bin(plan)
    db_md5 = hashlib.md5(db_bin).hexdigest().encode("ascii")
    db_checksum = base64.b64decode(plan["checksum_b64"])

    members = [
        ("db.bin", db_bin, 0o644),
        ("db.bin_md5", db_md5, 0o666),
        ("db.bin_checksum", db_checksum, 0o644),
    ]

    tar_buf = io.BytesIO()
    # Deterministic tar: fixed mtime, no owner names, GNU format (as produced
    # by the device). The router extracts members by name.
    with tarfile.open(fileobj=tar_buf, mode="w", format=tarfile.GNU_FORMAT) as tar:
        for name, payload, mode in members:
            info = tarfile.TarInfo(name)
            info.size = len(payload)
            info.mode = mode
            info.mtime = 0
            info.uid = info.gid = 0
            info.uname = info.gname = ""
            tar.addfile(info, io.BytesIO(payload))

    gz_buf = io.BytesIO()
    with gzip.GzipFile(fileobj=gz_buf, mode="wb", mtime=0) as gz:
        gz.write(tar_buf.getvalue())
    return gz_buf.getvalue()


def opener_with_cookies():
    jar = http.cookiejar.CookieJar()
    return urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))


def cgi_url(host):
    return f"http://{host}/index.cgi"


def login(opener, host, user, password):
    # Prime the session so the CGISID cookie is set before authenticating.
    opener.open(cgi_url(host), timeout=15).read()
    # Percent-encode the password from its latin-1 bytes so the wire bytes match
    # exactly what the firmware stored (the default UTF-8 would corrupt any
    # non-ASCII byte); the encoded form is still pure ASCII.
    body = urllib.parse.urlencode(
        {"req": "log_in", "username": user, "password": password},
        encoding="latin-1",
    ).encode("ascii")
    resp = opener.open(cgi_url(host), data=body, timeout=15).read()
    parsed = json.loads(resp.decode("latin-1"))
    if str(parsed.get("logged")) != "1":
        raise SystemExit(f"router login failed: {parsed.get('resp_body')}")


def select_page(opener, host, page):
    """Set the session's current page so the CGI routes the config upload.

    The upload is a file-only multipart POST carrying no request id; the firmware
    dispatches it by the session's current page (``curpg``), which the web UI
    establishes by opening the page first. The server persists ``curpg`` for the
    session, so this only needs to run once before the upload.
    """
    body = urllib.parse.urlencode(
        {"curpg": page, "curmenu": page, "req": "page_prereq"}
    ).encode("ascii")
    resp = opener.open(cgi_url(host), data=body, timeout=15).read()
    parsed = json.loads(resp.decode("latin-1"))
    if parsed.get("resp_t") != "page_prereq_resp":
        raise SystemExit(f"router: could not open {page}: {parsed.get('resp_body')}")


def upload_backup(opener, host, blob):
    boundary = "----icotera-config-restore-boundary"
    parts = [
        f"--{boundary}",
        f'Content-Disposition: form-data; name="{UPLOAD_FIELD}"; '
        f'filename="config.bin"',
        "Content-Type: application/octet-stream",
        "",
    ]
    body = "\r\n".join(parts).encode("latin-1") + b"\r\n"
    body += blob + b"\r\n"
    body += f"--{boundary}--\r\n".encode("latin-1")

    req = urllib.request.Request(cgi_url(host), data=body)
    req.add_header("Content-Type", f"multipart/form-data; boundary={boundary}")
    raw = opener.open(req, timeout=120).read().decode("latin-1", "replace")

    # The device signals a rejected restore in-band as HTTP 200 plus a JSON
    # envelope (the same shape a bad login returns: resp_t "error" with an
    # errcode), so a successful HTTP request is NOT a successful restore. The
    # success envelope is resp_t "upload_config_file_resp"; anything else is a
    # failure we must surface, or the systemd unit reports success on a no-op.
    try:
        parsed = json.loads(raw)
    except ValueError:
        raise SystemExit(f"router restore: non-JSON response: {raw[:400]!r}")

    resp_t = parsed.get("resp_t")
    resp_body = parsed.get("resp_body")
    resp_body = resp_body if isinstance(resp_body, dict) else {}
    if resp_t == "error":
        raise SystemExit(
            "router restore rejected: "
            f"errcode={resp_body.get('errcode')} errmsg={resp_body.get('errmsg')!r}"
        )
    if resp_t != "upload_config_file_resp":
        raise SystemExit(
            f"router restore: unexpected response type {resp_t!r}: {raw[:400]}"
        )
    # The upload envelope reports the applied-config result in `msg`; only
    # 1 (applied) and 2 (nothing to change) are a successful end state.
    msg = str(resp_body.get("msg"))
    if msg not in UPLOAD_OK:
        raise SystemExit(f"router restore failed (msg={msg}): {raw[:400]}")
    errorlines = resp_body.get("errorlines")
    if errorlines:
        raise SystemExit(f"router restore reported errors: {errorlines}")
    return (
        f"{UPLOAD_OK[msg]} "
        f"(applied={resp_body.get('success')}, failed={resp_body.get('failed')})"
    )


def cmd_generate(plan_path, out_path):
    with open(plan_path) as fh:
        plan = json.load(fh)
    blob = build_backup(plan)
    # The backup embeds the cleartext admin password and WPA passphrase, so it
    # must be root-only regardless of the service UMask or StateDirectory mode.
    fd = os.open(out_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "wb") as fh:
        fh.write(blob)
    os.chmod(out_path, 0o600)
    print(f"wrote {out_path} ({len(blob)} bytes)")


def cmd_push(plan_path):
    with open(plan_path) as fh:
        plan = json.load(fh)
    blob = build_backup(plan)
    login_cfg = plan["login"]
    password = read_secret(login_cfg["passwordFile"])

    opener = opener_with_cookies()
    host = plan["host"]
    try:
        print(f"logging in to {host} as {login_cfg['user']}")
        login(opener, host, login_cfg["user"], password)
        select_page(opener, host, CONFIG_PAGE)
        print(f"uploading {len(blob)}-byte config backup")
        result = upload_backup(opener, host, blob)
    except urllib.error.HTTPError as exc:
        raise SystemExit(f"router restore failed: HTTP {exc.code} {exc.reason}")
    except (urllib.error.URLError, OSError) as exc:
        # A transport failure mid-upload leaves the device in an unknown state.
        raise SystemExit(
            f"router {host} unreachable / transport failed: {exc}. "
            "Device state is unknown after a mid-transfer failure; verify on the "
            "web panel before retrying."
        )
    print(f"router restore accepted. response: {result[:400]}")


def main(argv):
    if len(argv) == 4 and argv[1] == "generate":
        cmd_generate(argv[2], argv[3])
    elif len(argv) == 3 and argv[1] == "push":
        cmd_push(argv[2])
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
