# gilbahat/homebrew-taps

A [Homebrew](https://brew.sh) tap for macOS emulation/tooling gadgets.

```sh
brew tap gilbahat/taps
```

## Formulae

| Formula | Description |
| --- | --- |
| [`vsock-emulation-layer`](https://github.com/gilbahat/vsock-emulation-layer) | Emulate Linux `AF_VSOCK` over Unix domain sockets on macOS |
| [`ding-libs`](https://github.com/SSSD/ding-libs) | Collection of C libraries from the SSSD project (hashes, INI parsing) |
| [`libverto`](https://github.com/latchset/libverto) | Async event loop abstraction library (libev + libevent backends) |

Install one with:

```sh
brew install vsock-emulation-layer   # or ding-libs, libverto
```

`ding-libs` and `libverto` are unmodified upstream libraries that build on
macOS; `ding-libs` carries one small backported patch for 64-bit `dev_t`
(inlined in the formula).

(after `brew tap gilbahat/taps`, or directly via
`brew install gilbahat/taps/vsock-emulation-layer`).
