#!/usr/bin/env python3
"""Merge an INI excerpt (KDE config format) into a target file.

Only the keys present in the excerpt are changed; everything else in the
target is preserved. Usage: apply_ini.py EXCERPT TARGET
"""
import re
import sys


def parse(path):
    groups, order, cur = {}, [], None
    try:
        lines = open(path, encoding="utf-8").read().splitlines()
    except FileNotFoundError:
        lines = []
    for line in lines:
        m = re.match(r"^\[(.*)\]$", line)
        if m:
            cur = m.group(1)
            if cur not in groups:
                groups[cur] = {}
                order.append(cur)
            continue
        if cur is not None and "=" in line and not line.lstrip().startswith("#"):
            k, v = line.split("=", 1)
            groups[cur][k] = v
    return groups, order


def main():
    src, dst = sys.argv[1], sys.argv[2]
    new, new_order = parse(src)
    cur, order = parse(dst)
    for g in new_order:
        if g not in cur:
            cur[g] = {}
            order.append(g)
        cur[g].update(new[g])
    with open(dst, "w", encoding="utf-8") as f:
        for g in order:
            f.write("[%s]\n" % g)
            for k, v in cur[g].items():
                f.write("%s=%s\n" % (k, v))
            f.write("\n")


if __name__ == "__main__":
    main()
