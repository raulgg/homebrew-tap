# pods-control builds from source with Swift and clang. It uses a private
# Apple audio API through a small DYLD interpose library; review the upstream
# source before installation.
class PodsControl < Formula
  desc "macOS CLI for AirPods and Beats listening modes"
  homepage "https://github.com/raulgg/pods-control"
  url "https://github.com/raulgg/pods-control/archive/refs/tags/v0.6.0.tar.gz"
  sha256 "0fe37e3de4087793299c2e2a66055a339e842992f9dda85837356e57cfbc6945"
  license "MIT"

  depends_on :macos

  conflicts_with "airpods-control",
                 because: "both install bin/pods-control and bin/airpods-control. " \
                          "Uninstall airpods-control before installing pods-control"

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
