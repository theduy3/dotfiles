---
name: entrypoint-exec-bit-strip
description: "Editing entrypoint.wylios.sh via any inode-replacing write (mv, python os.replace, some sed -i) strips +x -> container exit 126 crash loop"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4a24b86c-63d0-4a34-b503-ecb62ca81269
  modified: 2026-07-20T23:52:28.347Z
---

Any edit to `/root/hermes-wylios/entrypoint.wylios.sh` that REPLACES the inode
(`mv`, Python `os.replace`/`shutil.move`, `sed -i` on some builds) drops the
executable bit. The file becomes `0644`, Docker cannot `exec` it, the container
goes into `Restarting (126)` crash loop, and the whole hermes-wylios fleet is down.
`bash -n` passes (it IS valid bash) so syntax checks won't catch it.

**Why:** exit 126 = "cannot execute". The kernel refuses to exec a non-+x entrypoint.
Recurred 2026-07-20 (os.replace) after the same class on 2026-07-02 (mv). See [[salonx-mirror-personas]].

**How to apply:** after ANY edit to entrypoint.wylios.sh (or healthcheck.sh),
`chmod 755` it BEFORE `docker restart hermes-wylios`. When patching in Python,
`shutil.copymode(orig, tmp)` before `os.replace`, or `chmod` after. Recovery when
already crash-looping: `chmod 755 <entrypoint>` then `docker restart hermes-wylios`
(autoheal keeps PID 1 alive, so ~40s to healthy, no rebuild). Related: [[hermes-wylios-config-regen]].
