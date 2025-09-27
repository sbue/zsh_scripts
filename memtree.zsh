# Disk usage tree helpers (memtree).

_memtree_exec(){
  local label="$1"
  local threshold="${2:-1024}"
  local mode="${3:-tee}"
  python3 - "$label" "$threshold" "$mode" <<'PY'
import sys
import subprocess
import tempfile
import shutil
import re

def main():
    argv = sys.argv
    label = argv[1] if len(argv) > 1 else "memtree"
    threshold_mb = float(argv[2]) if len(argv) > 2 else 1024.0
    mode = argv[3] if len(argv) > 3 else "tee"
    try:
        output = subprocess.check_output(("tree", "--du", "-h"), stderr=subprocess.STDOUT)
    except FileNotFoundError:
        sys.stderr.write(f"{label}: tree command not found. Install with `brew install tree`.\n")
        return 1
    except subprocess.CalledProcessError as exc:
        output = exc.output or b""
    text = output.decode("utf-8", errors="replace")
    size_pattern = re.compile(r"\[\s*(\d+(?:\.\d+)?)\s*([KMGTPE])\]")
    units = {"K": 1.0/1024.0, "M": 1.0, "G": 1024.0, "T": 1024.0**2, "P": 1024.0**3, "E": 1024.0**4}
    lines = []
    for line in text.splitlines():
        match = size_pattern.search(line)
        if not match:
            continue
        value = float(match.group(1))
        unit = match.group(2)
        size_mb = value * units.get(unit, 0.0)
        if size_mb >= threshold_mb:
            lines.append(line)
    temp = tempfile.NamedTemporaryFile(mode="w", delete=False, encoding="utf-8", suffix=".txt", prefix="memtree-")
    try:
        if lines:
            temp.write("\n".join(lines))
            temp.write("\n")
    finally:
        temp_path = temp.name
        temp.close()
    if mode == "tee":
        if lines:
            sys.stdout.write("\n".join(lines))
            sys.stdout.write("\n")
    subl = shutil.which("subl")
    if subl:
        try:
            subprocess.Popen([subl, temp_path])
        except Exception as err:
            sys.stderr.write(f"{label}: failed to open Sublime Text: {err}\n")
    else:
        sys.stderr.write(f"{label}: subl not found; results in {temp_path}\n")
    sys.stderr.write(f"{label}: output saved to {temp_path}\n")
    return 0

if __name__ == "__main__":
    sys.exit(main())
PY
}

memtree(){
  _memtree_exec "memtree" "${1:-1024}" "tee"
}

memtree2(){
  _memtree_exec "memtree2" "${1:-1024}" "quiet"
}
