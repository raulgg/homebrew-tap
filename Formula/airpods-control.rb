# airpods-control builds from source with Swift and clang. It uses a private
# Apple audio API through a small DYLD interpose library; review the upstream
# source before installation.
class AirpodsControl < Formula
  desc "Control AirPods listening mode and Conversation Awareness from the CLI"
  homepage "https://github.com/raulgg/airpods-control"
  url "https://github.com/raulgg/airpods-control/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "de8e3301e51eca805998db2f273ad1e9ef6f2ab51ae6da270c444fae4c629168"
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
