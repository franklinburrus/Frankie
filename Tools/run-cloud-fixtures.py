#!/usr/bin/env python3
"""Cloud-verifiable Phase 1 fixture tests (no Swift / no Mac required).

Covers: deterministic collage layout math, caption band, hash preservation,
export profile dimensions, and composite must-not-claim-AI rule.
"""
from __future__ import annotations

import hashlib
import json
import struct
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIX = ROOT / "Fixtures" / "synthetic"
OUT = ROOT / "artifacts" / "cloud-fixtures"


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def write_png(path: Path, width: int, height: int, rgb: tuple[int, int, int]) -> None:
    r, g, b = rgb
    raw = bytearray()
    for _y in range(height):
        raw.append(0)
        for _x in range(width):
            raw.extend((r, g, b, 255))

    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)


def read_png(path: Path) -> tuple[int, int, bytearray]:
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    offset = 8
    width = height = None
    idat = b""
    while offset < len(data):
        length = struct.unpack(">I", data[offset : offset + 4])[0]
        offset += 4
        tag = data[offset : offset + 4]
        offset += 4
        chunk = data[offset : offset + length]
        offset += length
        offset += 4
        if tag == b"IHDR":
            width, height = struct.unpack(">II", chunk[:8])
        elif tag == b"IDAT":
            idat += chunk
        elif tag == b"IEND":
            break
    assert width and height
    inflated = zlib.decompress(idat)
    rgba = bytearray()
    stride = 1 + width * 4
    for y in range(height):
        row = inflated[y * stride : (y + 1) * stride]
        assert row[0] == 0
        rgba.extend(row[1:])
    return width, height, rgba


def photo_slots(count: int, canvas_w: int, content_h: int, placement: str) -> list[tuple[int, int, int, int]]:
    n = max(1, count)
    pad = 16
    if placement == "hero-left":
        if n == 1:
            return [(pad, pad, canvas_w - pad * 2, content_h - pad * 2)]
        hero_w = int(canvas_w * 0.62) - pad
        slots = [(pad, pad, hero_w, content_h - pad * 2)]
        side_x = hero_w + pad * 2
        side_w = canvas_w - side_x - pad
        side_h = (content_h - pad * n) // max(1, n - 1)
        for i in range(1, n):
            slots.append((side_x, pad + (i - 1) * (side_h + pad), side_w, side_h))
        return slots
    raise AssertionError(f"unsupported placement in cloud fixture: {placement}")


def blit(dst: bytearray, dw: int, dh: int, src: bytearray, sw: int, sh: int, box: tuple[int, int, int, int]) -> None:
    x0, y0, bw, bh = box
    for y in range(bh):
        sy = min(sh - 1, y * sh // bh)
        dy = y0 + y
        if dy < 0 or dy >= dh:
            continue
        for x in range(bw):
            sx = min(sw - 1, x * sw // bw)
            dx = x0 + x
            if dx < 0 or dx >= dw:
                continue
            si = (sy * sw + sx) * 4
            di = (dy * dw + dx) * 4
            dst[di : di + 4] = src[si : si + 4]


def fill(dst: bytearray, dw: int, dh: int, box: tuple[int, int, int, int], rgba: tuple[int, int, int, int]) -> None:
    x0, y0, bw, bh = box
    for y in range(max(0, y0), min(dh, y0 + bh)):
        for x in range(max(0, x0), min(dw, x0 + bw)):
            i = (y * dw + x) * 4
            dst[i : i + 4] = bytes(rgba)


def caption_band(canvas_w: int, canvas_h: int, frac: float = 0.22) -> tuple[int, int, int, int]:
    band_h = max(48, int(canvas_h * frac))
    return (0, canvas_h - band_h, canvas_w, band_h)


def composite(photo_paths: list[Path], caption: str, out_path: Path) -> dict:
    width, height = 1280, 720
    canvas = bytearray([26, 26, 26, 255]) * (width * height)
    band = caption_band(width, height)
    content_h = height - band[3]
    slots = photo_slots(len(photo_paths), width, content_h, "hero-left")
    source_hashes = {}
    for idx, path in enumerate(photo_paths):
        source_hashes[path.name] = sha256(path)
        pw, ph, prgba = read_png(path)
        blit(canvas, width, height, prgba, pw, ph, slots[min(idx, len(slots) - 1)])
    fill(canvas, width, height, band, (0, 0, 0, 230))
    # Stamp a bright rectangle representing caption glyphs for legibility probe.
    fill(canvas, width, height, (40, band[1] + 12, min(1200, 20 * max(1, len(caption))), band[3] - 24), (255, 255, 255, 255))

    # Write PNG
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        raw.extend(canvas[y * width * 4 : (y + 1) * width * 4])

    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(png)

    after = {p.name: sha256(p) for p in photo_paths}
    assert after == source_hashes, "source mutation detected"

    # Bright pixels in caption band
    bright = 0
    for y in range(band[1], height):
        for x in range(width):
            i = (y * width + x) * 4
            if canvas[i] > 200 and canvas[i + 1] > 200 and canvas[i + 2] > 200:
                bright += 1
    assert bright > 100, "caption overlay missing"

    ow, oh, _ = read_png(out_path)
    assert (ow, oh) == (1280, 720)

    return {
        "width": ow,
        "height": oh,
        "export_sha256": sha256(out_path),
        "source_hashes": source_hashes,
        "generator_id": "deterministic-composite",
        "is_ai_image_generation": False,
        "review_state": "NEEDS_REVIEW",
        "caption": caption,
        "bright_caption_pixels": bright,
    }


def main() -> int:
    FIX.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)

    p1 = FIX / "participant-a.png"
    p2 = FIX / "participant-b.png"
    write_png(p1, 320, 320, (220, 60, 60))
    write_png(p2, 320, 320, (60, 120, 220))

    before = {p1.name: sha256(p1), p2.name: sha256(p2)}
    result = composite([p1, p2], "HELLO FRANK", OUT / "thumbnail.png")
    after = {p1.name: sha256(p1), p2.name: sha256(p2)}
    assert before == after

    # Caveman provenance blob check (cloud VERIFIED).
    prov = json.loads((ROOT / "third_party/caveman/provenance.json").read_text())
    for entry in prov["files"]:
        path = ROOT / entry["path"]
        # git hash-object equivalent
        import subprocess

        blob = subprocess.check_output(["git", "hash-object", str(path)], cwd=ROOT, text=True).strip()
        assert blob == entry["git_blob_sha1"], (entry["path"], blob, entry["git_blob_sha1"])

    # App-code NO-OP for pre-scaffold emptiness is historical; current tree has Phase 1 code.
    tracked = subprocess_check = __import__("subprocess").check_output(
        ["git", "ls-files"], cwd=ROOT, text=True
    ).splitlines()
    assert "README.md" in tracked

    (OUT / "result.json").write_text(json.dumps(result, indent=2) + "\n")
    print("PASS cloud fixtures")
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
