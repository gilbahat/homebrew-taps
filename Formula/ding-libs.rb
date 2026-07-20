class DingLibs < Formula
  desc "Collection of C libraries from the SSSD project (hashes, INI parsing)"
  homepage "https://github.com/SSSD/ding-libs"
  url "https://github.com/SSSD/ding-libs/archive/refs/tags/0.7.0.tar.gz"
  sha256 "21ebba447cf1cf6f1adac6a97d0389a2c44d6fda52fc29cbfa50392d1f11c026"
  license "LGPL-3.0-or-later"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "gettext" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build

  # On macOS st_mtime/st_dev/st_ino are 64-bit, so the 0.7.0 INI metadata code
  # truncates them (and its st_dev > ULONG_MAX guard is bogus). Backport of
  # upstream commit ffeab42 ("INI: fix metadata collection on platforms with
  # 64-bit dev_t"), which is not in the 0.7.0 release.
  patch :DATA

  def install
    # The GitHub tag archive ships no generated configure; bootstrap it.
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-static", "--disable-nls", *std_configure_args
    system "make"
    system "make", "install"
    # Drop libtool archives; consumers link via pkg-config.
    rm(lib.glob("*.la"))
  end

  test do
    (testpath/"test.c").write <<~C
      #include <dhash.h>
      int main(void) {
        hash_table_t *tbl = NULL;
        if (hash_create(8, &tbl, NULL, NULL) != HASH_SUCCESS)
          return 1;
        hash_destroy(tbl);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-ldhash", "-o", "test"
    system "./test"
  end
end

__END__
diff --git a/ini/ini_metadata.c b/ini/ini_metadata.c
index ae36b72..9a930ad 100644
--- a/ini/ini_metadata.c
+++ b/ini/ini_metadata.c
@@ -172,8 +172,8 @@ int collect_metadata(uint32_t metaflags,
         }

         /* Modification time stamp */
-        snprintf(buff, CONVERSION_BUFFER, "%ld",
-                 (long int)file_stats.st_mtime);
+        snprintf(buff, CONVERSION_BUFFER, "%lld",
+                 (long long)file_stats.st_mtime);
         error = col_add_str_property(metasec,
                                      NULL,
                                      INI_META_KEY_MODIFIED,
@@ -197,23 +197,11 @@ int collect_metadata(uint32_t metaflags,
             return error;
         }

-        /* The device ID can actualy be bigger than
-         * 32-bits according to the type sizes.
-         * However it is probaly not going to happen
-         * on a real system.
-         * Add a check for this case.
-         */
-        if (file_stats.st_dev > ULONG_MAX) {
-            TRACE_ERROR_NUMBER("Device is out of range", ERANGE);
-            col_destroy_collection(metasec);
-            return ERANGE;
-        }
-
         /* Device  ID */
         TRACE_INFO_LNUMBER("Device ID", file_stats.st_dev);

-        snprintf(buff, CONVERSION_BUFFER, "%lu",
-                 (unsigned long)file_stats.st_dev);
+        snprintf(buff, CONVERSION_BUFFER, "%llu",
+                 (unsigned long long)file_stats.st_dev);
         error = col_add_str_property(metasec,
                                      NULL,
                                      INI_META_KEY_DEV,
@@ -226,8 +214,8 @@ int collect_metadata(uint32_t metaflags,
         }

         /* i-node */
-        snprintf(buff, CONVERSION_BUFFER, "%lu",
-                (unsigned long)file_stats.st_ino);
+        snprintf(buff, CONVERSION_BUFFER, "%llu",
+                (unsigned long long)file_stats.st_ino);
         error = col_add_str_property(metasec,
                                      NULL,
                                      INI_META_KEY_INODE,
@@ -414,14 +402,14 @@ int config_access_check(struct collection_item *metadata,

 }

-static unsigned long get_checked_value(struct collection_item *metadata,
-                                       const char *key,
-                                       int *err)
+static uint64_t get_checked_value(struct collection_item *metadata,
+                                            const char *key,
+                                            int *err)
 {

     int error = EOK;
     struct collection_item *item = NULL;
-    unsigned long value;
+    uint64_t value;

     TRACE_FLOW_STRING("get_checked_value", "Entry");
     TRACE_INFO_STRING("Key", key);
@@ -445,8 +433,8 @@ static unsigned long get_checked_value(struct collection_item *metadata,
         return 0;
     }

-    value = get_ulong_config_value(item, 1, -1, &error);
-    if ((error) || (value == -1)) {
+    value = get_uint64_config_value(item, 1, 0, &error);
+    if (error) {
         TRACE_ERROR_NUMBER("Conversion failed", EINVAL);
         *err = EINVAL;
         return 0;
@@ -467,7 +455,7 @@ int config_changed(struct collection_item *metadata,
 {
     int error = EOK;
     struct collection_item *md[2];
-    unsigned long value[3][2];
+    uint64_t value[3][2];
     const char *key[] = { INI_META_KEY_MODIFIED,
                           INI_META_KEY_DEV,
                           INI_META_KEY_INODE };
