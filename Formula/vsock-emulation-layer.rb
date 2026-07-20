class VsockEmulationLayer < Formula
  desc "Emulate Linux AF_VSOCK over Unix domain sockets on macOS"
  homepage "https://github.com/gilbahat/vsock-emulation-layer"
  url "https://github.com/gilbahat/vsock-emulation-layer/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "66bf358c90650e0a73751457336151e1f7f27c1b736184ea57a07def4a6a702e"
  license "ISC"

  depends_on :macos

  def install
    system "make"
    system "make", "install", "PREFIX=#{prefix}"
    # Give the dylib an absolute install name so linkers (tier 2) resolve it
    # without an explicit -rpath.
    system "install_name_tool", "-id", "#{lib}/libvsock_unix.dylib",
                                "#{lib}/libvsock_unix.dylib"
  end

  test do
    # CLI runs and reports usage on bad args (exit code 2).
    assert_match "usage", shell_output("#{bin}/vsock-emu 2>&1", 2)

    # The dylib and header are installed and consumable: compile a tiny program
    # against the convention header and exercise a helper (creates an AF_UNIX
    # socket under the hood).
    assert_path_exists lib/"libvsock_unix.dylib"
    (testpath/"probe.c").write <<~C
      #include "vsock_unix.h"
      int main(void) { return vsock_unix_socket() >= 0 ? 0 : 1; }
    C
    system ENV.cc, "probe.c", "-I#{include}", "-o", "probe"
    system "./probe"
  end
end
