# airpods-control builds from source with Swift and clang. It uses a private
# Apple audio API through a small DYLD interpose library; review the upstream
# source before installation.
class AirpodsControl < Formula
  desc "Control AirPods listening mode and Conversation Awareness from the CLI"
  homepage "https://github.com/raulgg/airpods-control"
  url "https://github.com/raulgg/airpods-control/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "53c7f9ed1846e2dab806301521bee8c3742149e2b4c45c9abf9b2550edd817ad"
  license "MIT"

  depends_on :macos

  def install
    system "make", "install",
           "PREFIX=#{prefix}",
           "ARCHS=#{Hardware::CPU.arch}",
           "CLANG=/usr/bin/clang",
           "SWIFTC=/usr/bin/swiftc",
           "LIPO=/usr/bin/lipo",
           "CODESIGN=/usr/bin/codesign"
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/airpods-control --version").strip
  end
end
