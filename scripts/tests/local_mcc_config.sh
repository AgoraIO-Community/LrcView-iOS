#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

git check-ignore -q Demo/Demo/localConfig.swift
if git ls-files --error-unmatch Demo/Demo/localConfig.swift >/dev/null 2>&1; then
    echo 'localConfig.swift is tracked by Git' >&2
    exit 1
fi
rg -q 'LocalMccConfig\.mccAppId' Demo/Demo/Config.swift
rg -q 'LocalMccConfig\.mccCertif' Demo/Demo/Config.swift
rg -q 'LocalMccConfig\.rtcAppId' Demo/Demo/Config.swift
rg -q 'LocalMccConfig\.accessUrl' Demo/Demo/Config.swift
rg -q 'LocalMccConfig\.pid' Demo/Demo/Config.swift
rg -q 'LocalMccConfig\.pKey' Demo/Demo/Config.swift
rg -q 'LocalMccConfig\.mccDomain\.trimmingCharacters\(in: \.whitespacesAndNewlines\)' Demo/Demo/Config.swift
rg -q 'domain\.isEmpty \? nil : domain' Demo/Demo/Config.swift
rg -q 'if let mccDomain = Config\.mccDomain' Demo/Demo/Other/Utils/MccManager.swift
rg -q 'config\.mccDomain = mccDomain' Demo/Demo/Other/Utils/MccManager.swift
rg -q 'static let mccDomain[[:space:]]*=' Demo/Demo/localConfig.swift
rg -q 'static let mccDomain = ""' Demo/Demo/localConfig.example.swift
test "$(rg -c 'localConfig\.swift in Sources' Demo/Demo.xcodeproj/project.pbxproj)" -eq 2
swiftc -typecheck -module-cache-path /private/tmp/klyrics-local-mcc-config-cache Demo/Demo/localConfig.swift
plutil -lint Demo/Demo.xcodeproj/project.pbxproj
