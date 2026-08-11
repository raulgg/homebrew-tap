# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "rbconfig"
require "tmpdir"

class UpdateAirpodsControlTest < Minitest::Test
  SCRIPT = File.expand_path("../scripts/update-airpods-control.rb", __dir__).freeze
  OLD_CHECKSUM = "1" * 64
  NEW_CHECKSUM = "2" * 64

  def run_updater(current_version:, current_checksum:, tag:, checksum:)
    Dir.mktmpdir do |directory|
      formula = File.join(directory, "airpods-control.rb")
      File.write(formula, <<~RUBY)
        class AirpodsControl < Formula
          url "https://github.com/raulgg/airpods-control/archive/refs/tags/v#{current_version}.tar.gz"
          sha256 "#{current_checksum}"
        end
      RUBY

      stdout, stderr, status = Open3.capture3(
        { "AIRPODS_CONTROL_FORMULA_PATH" => formula },
        RbConfig.ruby, SCRIPT, tag, checksum
      )
      return stdout, stderr, status, File.read(formula)
    end
  end

  def test_updates_to_a_newer_release
    stdout, stderr, status, formula = run_updater(
      current_version: "1.2.3", current_checksum: OLD_CHECKSUM,
      tag: "v1.3.0", checksum: NEW_CHECKSUM
    )

    assert status.success?, stderr
    assert_includes stdout, "Updated"
    assert_includes formula, "v1.3.0.tar.gz"
    assert_includes formula, NEW_CHECKSUM
  end

  def test_replay_of_same_release_and_checksum_is_a_no_op
    stdout, stderr, status, formula = run_updater(
      current_version: "1.2.3", current_checksum: OLD_CHECKSUM,
      tag: "v1.2.3", checksum: OLD_CHECKSUM
    )

    assert status.success?, stderr
    assert_includes stdout, "already references"
    assert_includes formula, OLD_CHECKSUM
  end

  def test_rejects_checksum_change_for_an_existing_release
    _stdout, stderr, status, formula = run_updater(
      current_version: "1.2.3", current_checksum: OLD_CHECKSUM,
      tag: "v1.2.3", checksum: NEW_CHECKSUM
    )

    refute status.success?
    assert_includes stderr, "refusing changed archive checksum"
    assert_includes formula, OLD_CHECKSUM
  end

  def test_rejects_downgrade
    _stdout, stderr, status, formula = run_updater(
      current_version: "1.2.3", current_checksum: OLD_CHECKSUM,
      tag: "v1.2.2", checksum: NEW_CHECKSUM
    )

    refute status.success?
    assert_includes stderr, "refusing downgrade"
    assert_includes formula, "v1.2.3.tar.gz"
  end
end
