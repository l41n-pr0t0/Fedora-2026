#!/usr/bin/env bash
# Fails (exit 1) if the repo contains things that look personal or secret.
# Run before every commit:  tools/privacy-scan.sh
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2
pat='/home/[a-z0-9_-]+|BEGIN [A-Z ]*PRIVATE KEY|ghp_[A-Za-z0-9]{20,}|github_pat_|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|(password|passwd|secret|token|api_?key) *[=:] *["'"'"'][^"'"'"']{4,}["'"'"']|([0-9]{1,3}\.){3}[0-9]{1,3}|([0-9a-f]{2}:){5}[0-9a-f]{2}|[A-Za-z0-9._%+-]+@(gmail|outlook|yahoo|proton|hotmail)\.[a-z]+'
hits=$(grep -rIniE "$pat" --exclude-dir=.git --exclude=privacy-scan.sh . | grep -v '@HOME@' | grep -v 'SPDX-FileCopyrightText' | grep -vE '(KdeControlStation-patched|AndromedaLauncher-wired)/metadata.json.*Email' | grep -v 'Copyright (C) 20' | grep -vE '\.svg:' | grep -v '192\.168\.1\.0/24')
if [ -n "$hits" ]; then echo "$hits" | cut -c1-200; echo; echo "privacy-scan: review the lines above"; exit 1; fi
echo "privacy-scan: clean"
