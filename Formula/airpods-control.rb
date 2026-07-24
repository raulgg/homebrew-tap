# airpods-control builds from source with Swift and clang. It uses a private
# Apple audio API through a small DYLD interpose library; review the upstream
# source before installation.
class AirpodsControl < Formula
  desc "Control AirPods listening mode and Conversation Awareness from the CLI"
  homepage "https://github.com/raulgg/airpods-control"
  url "https://github.com/raulgg/airpods-control/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "61d3059c49490fef655825fbc6a40261ad4325d42b190cc65aa124f3fb41b11c"
  license "MIT"

  depends_on :macos

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/airpods-control --version").strip
  end
end
