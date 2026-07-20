class Libverto < Formula
  desc "Async event loop abstraction library"
  homepage "https://github.com/latchset/libverto"
  url "https://github.com/latchset/libverto/releases/download/0.3.1/libverto-0.3.1.tar.gz"
  sha256 "983817c6bc0af6fa3731da2653e6371f6e1a56b4489ee44b3172e918574c50ea"
  license "MIT"

  depends_on "pkgconf" => :build
  depends_on "libev"
  depends_on "libevent"

  def install
    system "./configure", "--disable-silent-rules",
                          "--disable-static",
                          "--with-libev",
                          "--with-libevent",
                          "--without-glib",
                          "--without-tevent",
                          *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <verto.h>
      int main(void) {
        verto_ctx *ctx = verto_default(NULL, VERTO_EV_TYPE_IO);
        verto_free(ctx);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lverto", "-o", "test"
    system "./test"
  end
end
