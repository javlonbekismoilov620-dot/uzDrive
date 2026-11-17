#!/usr/bin/env python3
"""Single command to bump the app version everywhere it must stay in sync.

  python3 tools/bump_version.py 1.0.1          # sets name 1.0.1, build code +1
  python3 tools/bump_version.py 1.1.0 --code 7 # explicit build number

Updates:
  project.godot       application/config/version
  export_presets.cfg  Android version/name + version/code, iOS short_version + version
"""
import re, sys, os

ROOT = os.path.join(os.path.dirname(__file__), "..")


def main():
    if len(sys.argv) < 2 or not re.match(r"^\d+\.\d+\.\d+$", sys.argv[1]):
        print(__doc__)
        sys.exit(1)
    name = sys.argv[1]
    pres_path = os.path.join(ROOT, "export_presets.cfg")
    pres = open(pres_path, encoding="utf-8").read()
    cur = int(re.search(r"version/code=(\d+)", pres).group(1))
    code = int(sys.argv[sys.argv.index("--code") + 1]) if "--code" in sys.argv else cur + 1
    if code <= cur:
        print(f"build code must increase (current {cur})")
        sys.exit(1)
    pres = re.sub(r'version/code=\d+', f'version/code={code}', pres)
    pres = re.sub(r'version/name="[^"]*"', f'version/name="{name}"', pres)
    pres = re.sub(r'application/short_version="[^"]*"', f'application/short_version="{name}"', pres)
    pres = re.sub(r'application/version="[^"]*"', f'application/version="{code}"', pres)
    open(pres_path, "w", encoding="utf-8").write(pres)
    proj_path = os.path.join(ROOT, "project.godot")
    proj = open(proj_path, encoding="utf-8").read()
    proj = re.sub(r'config/version="[^"]*"', f'config/version="{name}"', proj)
    open(proj_path, "w", encoding="utf-8").write(proj)
    print(f"version {name} (build {code})")


if __name__ == "__main__":
    main()
