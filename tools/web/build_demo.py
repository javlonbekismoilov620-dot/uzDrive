#!/usr/bin/env python3
"""Assembles the playable web demo from a Godot "Web" export.

  godot --headless --path . --export-release "Web" build/web/uzdrive.html
  python3 tools/web/build_demo.py build/web build/web-demo

Output folder (static files, host anywhere over HTTPS - no special headers needed):
  index.html                       page (engine JS inlined, loader, loading screen)
  index.full.html                  same page wrapped in a complete HTML document
  engine.wasm                      gzip-compressed uzdrive.wasm (decompressed in the browser)
  gamedata.wasm                    game data (uzdrive.pck; .wasm name so strict static hosts serve it)
  uzdrive.audio.worklet.js, uzdrive.audio.position.worklet.js
`index.html` is a body fragment for hosts that add their own document skeleton
(claude.ai Artifacts); use `index.full.html` (rename to index.html) for itch.io,
GitHub Pages, Netlify, etc.
"""
import gzip, os, shutil, sys

HERE = os.path.dirname(os.path.abspath(__file__))


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else "build/web"
    out = sys.argv[2] if len(sys.argv) > 2 else "build/web-demo"
    os.makedirs(out, exist_ok=True)
    wasm = open(os.path.join(src, "uzdrive.wasm"), "rb").read()
    gz = gzip.compress(wasm, compresslevel=9, mtime=0)
    open(os.path.join(out, "engine.wasm"), "wb").write(gz)
    shutil.copy(os.path.join(src, "uzdrive.pck"), os.path.join(out, "gamedata.wasm"))
    for f in ["uzdrive.audio.worklet.js", "uzdrive.audio.position.worklet.js"]:
        shutil.copy(os.path.join(src, f), os.path.join(out, f))
    engine_js = open(os.path.join(src, "uzdrive.js"), encoding="utf-8").read()
    assert "</script" not in engine_js.lower(), "engine JS cannot be inlined safely"
    pck_size = os.path.getsize(os.path.join(out, "gamedata.wasm"))
    shell = open(os.path.join(HERE, "demo_shell.html"), encoding="utf-8").read()
    page = (shell.replace("__ENGINE_JS__", engine_js)
            .replace("__GZ_BYTES__", str(len(gz)))
            .replace("__WASM_BYTES__", str(len(wasm)))
            .replace("__PCK_BYTES__", str(pck_size))
            .replace("__TOTAL_MB__", "%.1f" % ((len(gz) + pck_size) / 1048576)))
    open(os.path.join(out, "index.html"), "w", encoding="utf-8").write(page)
    full = ('<!doctype html>\n<html lang="uz">\n<head>\n<meta charset="utf-8">\n'
            '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n'
            '<meta name="apple-mobile-web-app-capable" content="yes">\n'
            '<meta name="theme-color" content="#0c1424">\n</head>\n<body>\n' + page + '\n</body>\n</html>\n')
    open(os.path.join(out, "index.full.html"), "w", encoding="utf-8").write(full)
    print("demo written to %s: engine %.1f MB (gz from %.1f MB), pack %.1f MB, page %.0f KB" % (
        out, len(gz) / 1048576, len(wasm) / 1048576, pck_size / 1048576, len(page) / 1024))


if __name__ == "__main__":
    main()
