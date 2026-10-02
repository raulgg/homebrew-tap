# pods-control builds from source with Swift and clang. It uses a private
# Apple audio API through a small DYLD interpose library; review the upstream
# source before installation.
class PodsControl < Formula
  desc "macOS CLI for AirPods and Beats listening modes"
  homepage "https://github.com/raulgg/pods-control"
  url "https://github.com/raulgg/pods-control/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "454fb494937fd1f6e48db6542e3726fe164e010cdb8580adc475de906263a775"
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
