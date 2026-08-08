# airpods-control builds from source with Swift and clang. It uses a private
# Apple audio API through a small DYLD interpose library; review the upstream
# source before installation.
class AirpodsControl < Formula
  desc "Control AirPods listening mode and Conversation Awareness from the CLI"
  homepage "https://github.com/raulgg/airpods-control"
  url "https://github.com/raulgg/airpods-control/archive/refs/tags/v0.2.1.tar.gz"
  sha256 "64c8f86862086813d59b87a0346d0e737e5d9471a044af3bdc326f17b51f89fa"
  license "MIT"

  depends_on :macos

  def install
    system "make", "install",
           "PREFIX=#{prefix}",
           "CLANG=/usr/bin/clang",
           "SWIFTC=/usr/bin/swiftc",
           "LIPO=/usr/bin/lipo",
           "CODESIGN=/usr/bin/codesign"
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/airpods-control --version").strip
  end
end
