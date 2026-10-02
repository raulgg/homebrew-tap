# airpods-control is the deprecated formula name. It builds the same source
# as pods-control. The build uses Swift, clang, and a private Apple audio API
# through a small DYLD interpose library; review the upstream source before
# installation.
class AirpodsControl < Formula
  desc "macOS CLI for AirPods and Beats listening modes"
  homepage "https://github.com/raulgg/pods-control"
  url "https://github.com/raulgg/pods-control/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "454fb494937fd1f6e48db6542e3726fe164e010cdb8580adc475de906263a775"
  license "MIT"

  deprecate! date:                "2026-10-02",
             because:             "has been renamed to pods-control; uninstall it before installing the replacement",
             replacement_formula: "raulgg/tap/pods-control"
  disable! date:                "2027-10-02",
           because:             "has been renamed to pods-control; uninstall it before installing the replacement",
           replacement_formula: "raulgg/tap/pods-control"

  depends_on :macos

  conflicts_with "pods-control",
                 because: "both install bin/pods-control and bin/airpods-control. " \
                          "Uninstall airpods-control, then run: " \
                          "brew install --formula raulgg/tap/pods-control"

  def install
    system "make", "install",
           "PREFIX=#{prefix}",
           "ARCHS=#{Hardware::CPU.arch}",
           "CLANG=/usr/bin/clang",
           "SWIFTC=/usr/bin/swiftc",
           "LIPO=/usr/bin/lipo",
           "CODESIGN=/usr/bin/codesign"
  end

  def caveats
    <<~EOS
      This formula is the old name. Upgrades stay in Cellar/airpods-control
      and install the same pods-control release, including the airpods-control
      command.

      To switch to the new formula, uninstall first:

        brew uninstall --formula airpods-control
        brew install --formula raulgg/tap/pods-control

      The install line trusts only raulgg/tap/pods-control. Running it
      while this formula is linked fails. Unlinking is not enough: the
      old formula stays installed and a later upgrade then fails.
    EOS
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/airpods-control --version").strip
  end
end
