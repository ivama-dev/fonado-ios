#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
CHECK_BUILD_DIR="${FONADO_CHECK_BUILD_DIR:-build/checks}"
mkdir -p "$CHECK_BUILD_DIR/module-cache"
swiftc -parse-as-library -module-cache-path "$CHECK_BUILD_DIR/module-cache" \
  FonadoAI/CallSession.swift FonadoAI/SIPAccount.swift FonadoAI/SIPCore.swift FonadoAI/Diagnostics.swift \
  FonadoAI/SIPConnectionCoordinator.swift Checks/SIPConnectionChecks.swift -o "$CHECK_BUILD_DIR/SIPConnectionChecks"
"$CHECK_BUILD_DIR/SIPConnectionChecks"
swiftc -parse-as-library -module-cache-path "$CHECK_BUILD_DIR/module-cache" \
  FonadoAI/CallSession.swift FonadoAI/SIPAccount.swift FonadoAI/SIPCore.swift FonadoAI/Diagnostics.swift \
  FonadoAI/IncomingCallCoordinator.swift FonadoAI/CallManager.swift Checks/CallFlowChecks.swift -o "$CHECK_BUILD_DIR/CallFlowChecks"
"$CHECK_BUILD_DIR/CallFlowChecks"
swiftc -parse-as-library -module-cache-path "$CHECK_BUILD_DIR/module-cache" \
  FonadoAI/CallSession.swift FonadoAI/DeviceContact.swift Checks/ContactSearchChecks.swift \
  -o "$CHECK_BUILD_DIR/ContactSearchChecks"
"$CHECK_BUILD_DIR/ContactSearchChecks"
swiftc -parse-as-library -module-cache-path "$CHECK_BUILD_DIR/module-cache" \
  FonadoAI/SIPAccount.swift Checks/NATChecks.swift -o "$CHECK_BUILD_DIR/NATChecks"
"$CHECK_BUILD_DIR/NATChecks"
swiftc -parse-as-library -module-cache-path "$CHECK_BUILD_DIR/module-cache" \
  FonadoAI/CallSession.swift FonadoAI/SIPAccount.swift FonadoAI/SIPCore.swift FonadoAI/Diagnostics.swift \
  FonadoAI/IncomingCallCoordinator.swift Checks/IncomingCallChecks.swift -o "$CHECK_BUILD_DIR/IncomingCallChecks"
"$CHECK_BUILD_DIR/IncomingCallChecks"
plutil -lint FonadoAI.xcodeproj/project.pbxproj

swiftc -parse-as-library -module-cache-path "$CHECK_BUILD_DIR/module-cache" \
  FonadoAI/CallSession.swift Checks/CallHistoryChecks.swift -o "$CHECK_BUILD_DIR/CallHistoryChecks"
"$CHECK_BUILD_DIR/CallHistoryChecks"

swiftc -parse-as-library -module-cache-path "$CHECK_BUILD_DIR/module-cache" \
  FonadoAI/CallSession.swift Checks/CloudHistoryChecks.swift -o "$CHECK_BUILD_DIR/CloudHistoryChecks"
"$CHECK_BUILD_DIR/CloudHistoryChecks"
python3 Checks/cloud-history-sync-checks.py

swiftc -parse-as-library -module-cache-path "$CHECK_BUILD_DIR/module-cache" \
  FonadoAI/CallSession.swift FonadoAI/SIPAccount.swift FonadoAI/SystemCallActivity.swift \
  Checks/SystemCallActivityChecks.swift -o "$CHECK_BUILD_DIR/SystemCallActivityChecks"
"$CHECK_BUILD_DIR/SystemCallActivityChecks"

# Both apps compile these same models and presentation state.
swiftc -parse-as-library -module-cache-path "$CHECK_BUILD_DIR/module-cache" \
  FonadoAI/CallSession.swift FonadoAI/TeamMember.swift FonadoAI/TeamDirectory.swift \
  Checks/TeamDirectoryChecks.swift -o "$CHECK_BUILD_DIR/TeamDirectoryChecks"
"$CHECK_BUILD_DIR/TeamDirectoryChecks"
swiftc -parse-as-library -module-cache-path "$CHECK_BUILD_DIR/module-cache" \
  FonadoAI/CallSession.swift FonadoAI/TeamMember.swift Checks/DeviceProfileChecks.swift \
  -o "$CHECK_BUILD_DIR/DeviceProfileChecks"
"$CHECK_BUILD_DIR/DeviceProfileChecks"
python3 Checks/siri-vocabulary-checks.py
swiftc -parse-as-library -module-cache-path "$CHECK_BUILD_DIR/module-cache" \
  FonadoAI/CallSession.swift FonadoAI/TeamMember.swift FonadoAI/DeviceContact.swift Checks/TeamPresenceChecks.swift \
  -o "$CHECK_BUILD_DIR/TeamPresenceChecks"
"$CHECK_BUILD_DIR/TeamPresenceChecks"

swiftc -parse-as-library -module-cache-path "$CHECK_BUILD_DIR/module-cache" \
  FonadoAI/CallSession.swift FonadoAI/FavoriteGroups.swift Checks/FavoriteGroupChecks.swift \
  -o "$CHECK_BUILD_DIR/FavoriteGroupChecks"
"$CHECK_BUILD_DIR/FavoriteGroupChecks"
python3 Checks/favorite-sync-checks.py
