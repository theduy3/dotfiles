---
name: sip-restricted-and-simctl
description: "SIP refuses root on restricted paths so no sudo variant works; and xcrun 'not a developer tool' means unresolvable, not missing — simctl lives in CoreSimulator.framework"
metadata:
  node_type: memory
  type: reference
  modified: 2026-09-09
---

Two traps, both hit on 2026-09-09 while reclaiming 11.4 GB of orphaned simulator runtimes.

## 1. `Operation not permitted` under sudo means SIP, and no sudo variant will help

`sudo rm -rf /System/Library/AssetsV2/com_apple_MobileAsset_iOSSimulatorRuntime` returned
`Operation not permitted` on every file. `sudo hdiutil detach /dev/disk5` returned `Resource busy`.

Diagnose it with two commands:

- `ls -ldO <path>` — a `restricted` flag in the output means SIP owns the path.
- `csrutil status` — `enabled` confirms SIP is enforcing.

**SIP refuses root.** Escalating privileges, retrying, or varying the `rm` flags cannot succeed. The
only paths forward are the system's own manager for that data, or disabling SIP from Recovery — and
the first is almost always correct.

## 2. `xcrun: not a developer tool` means UNRESOLVABLE, not missing

`xcrun simctl` reported `unable to find utility "simctl", not a developer tool or in PATH`. That
reads as "simctl is not installed". It is not what happened. `xcode-select -p` pointed at
`/Library/Developer/CommandLineTools`, which has no `simctl`, so `xcrun` could not resolve it.

The binary was present the whole time:

```
/Library/Developer/PrivateFrameworks/CoreSimulator.framework/Resources/bin/simctl
```

Called by absolute path it works with **no Xcode installed and no sudo**. Before concluding a
developer tool is absent, look in `/Library/Developer/PrivateFrameworks/` — CoreSimulator survives
an Xcode uninstall, and `simdiskimaged` keeps running from it.

## How to apply — removing orphaned simulator runtimes

1. List them: `<simctl-path> runtime list` — prints `Total Disk Images: N (size)`.
2. Delete by UUID: `<simctl-path> runtime delete <UUID>`.
3. The delete is **asynchronous**. State shows `Deleting`; poll `runtime list` until
   `Total Disk Images: 0`. It took about 15 seconds for two runtimes.

This works because `simctl` delegates to `simdiskimaged`, which owns the assets and holds the
entitlements SIP requires. It also clears the CoreSimulator dyld cache, so expect to reclaim more
than the reported image size — `/Library/Developer` went 32 GB to 2.1 GB against an 11.4 GB
estimate.

⚠️ `du` on `/Library/Developer/CoreSimulator/Volumes/*` overstates the reclaim. Those are mounted
sealed read-only APFS volumes, so `du` measures decompressed content. The real figure is the `.dmg`
under `/System/Library/AssetsV2/`, and `simctl runtime list` reports it directly. Trust `simctl`.
