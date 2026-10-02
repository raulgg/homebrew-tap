# typed: strict
# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "rbconfig"
require "tmpdir"

class UpdatePodsControlTest < Minitest::Test
  SCRIPT = File.expand_path("../scripts/update-pods-control.rb", __dir__).freeze
  OLD_CHECKSUM = "1" * 64
  NEW_CHECKSUM = "2" * 64
  DEPRECATION = 'deprecate! date: "2026-10-02", because: "has been renamed to pods-control"'

  def formula_source(version, checksum)
    <<~RUBY
      class Example < Formula
        url "https://github.com/raulgg/pods-control/archive/refs/tags/v#{version}.tar.gz"
        sha256 "#{checksum}"
        #{DEPRECATION}
      end
    RUBY
  end

  def run_updater(current_version:, current_checksum:, tag:, checksum:,
                  airpods_version: nil, airpods_checksum: nil, omit: nil)
    airpods_version ||= current_version
    airpods_checksum ||= current_checksum

    Dir.mktmpdir do |directory|
      sources = {
        "pods-control.rb"    => formula_source(current_version, current_checksum),
        "airpods-control.rb" => formula_source(airpods_version, airpods_checksum),
      }
      sources.delete(omit) if omit
      sources.each do |name, body|
        File.write(File.join(directory, name), body)
      end

      # Homebrew's Linux container has no `ruby` on PATH, so reuse this test's interpreter.
      stdout, stderr, status = Open3.capture3(
        { "PODS_CONTROL_FORMULA_DIR" => directory },
        RbConfig.ruby, SCRIPT, tag, checksum
      )
      bodies = sources.keys.to_h { |name| [name, File.read(File.join(directory, name))] }
      return stdout, stderr, status, bodies
    end
  end

  def test_updates_to_a_newer_release
    stdout, stderr, status, bodies = run_updater(
      current_version: "1.2.3", current_checksum: OLD_CHECKSUM,
      tag: "v1.3.0", checksum: NEW_CHECKSUM
    )

    assert status.success?, stderr
    assert_includes stdout, "Updated"
    bodies.each_value do |formula|
      assert_includes formula, "https://github.com/raulgg/pods-control/archive/refs/tags/v1.3.0.tar.gz"
      assert_includes formula, NEW_CHECKSUM
      assert_includes formula, DEPRECATION
      refute_includes formula, OLD_CHECKSUM
    end
  end

  def test_replay_of_same_release_and_checksum_is_a_no_op
    stdout, stderr, status, bodies = run_updater(
      current_version: "1.2.3", current_checksum: OLD_CHECKSUM,
      tag: "v1.2.3", checksum: OLD_CHECKSUM
    )

    assert status.success?, stderr
    assert_includes stdout, "already reference"
    bodies.each_value do |formula|
      assert_includes formula, OLD_CHECKSUM
      assert_includes formula, DEPRECATION
    end
  end

  def test_rejects_checksum_change_for_an_existing_release
    _stdout, stderr, status, bodies = run_updater(
      current_version: "1.2.3", current_checksum: OLD_CHECKSUM,
      tag: "v1.2.3", checksum: NEW_CHECKSUM
    )

    refute status.success?
    assert_includes stderr, "refusing changed archive checksum"
    bodies.each_value do |formula|
      assert_includes formula, OLD_CHECKSUM
    end
  end

  def test_rejects_downgrade
    _stdout, stderr, status, bodies = run_updater(
      current_version: "1.2.3", current_checksum: OLD_CHECKSUM,
      tag: "v1.2.2", checksum: NEW_CHECKSUM
    )

    refute status.success?
    assert_includes stderr, "refusing downgrade"
    bodies.each_value do |formula|
      assert_includes formula, "v1.2.3.tar.gz"
      refute_includes formula, NEW_CHECKSUM
    end
  end

  def test_rejects_disagreement_between_formulae
    _stdout, stderr, status, bodies = run_updater(
      current_version: "1.2.3", current_checksum: OLD_CHECKSUM,
      airpods_version: "1.2.2",
      tag: "v1.3.0", checksum: NEW_CHECKSUM
    )

    refute status.success?
    assert_includes stderr, "formulae disagree on version or checksum"
    assert_includes bodies.fetch("pods-control.rb"), "v1.2.3.tar.gz"
    assert_includes bodies.fetch("airpods-control.rb"), "v1.2.2.tar.gz"
    bodies.each_value do |formula|
      refute_includes formula, NEW_CHECKSUM
    end
  end

  def test_rejects_a_missing_formula
    _stdout, stderr, status, bodies = run_updater(
      current_version: "1.2.3", current_checksum: OLD_CHECKSUM,
      tag: "v1.3.0", checksum: NEW_CHECKSUM,
      omit: "airpods-control.rb"
    )

    refute status.success?
    assert_includes stderr, "missing formula file"
    assert_includes bodies.fetch("pods-control.rb"), "v1.2.3.tar.gz"
    refute_includes bodies.fetch("pods-control.rb"), NEW_CHECKSUM
  end
end
