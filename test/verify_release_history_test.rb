# typed: strict
# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "shellwords"
require "tmpdir"

class VerifyReleaseHistoryTest < Minitest::Test
  SCRIPT = File.expand_path("../scripts/verify-release-history.sh", __dir__).freeze
  REPOSITORY = "repos/raulgg/airpods-control"
  SHA = ("a" * 40).freeze
  TAG_COMMAND = "api #{REPOSITORY}/commits/refs/tags/v0.3.1 --jq .sha".freeze
  MAIN_COMMAND = "api #{REPOSITORY}/compare/#{SHA}...main --jq .status".freeze
  MAINTENANCE_COMMAND = "api #{REPOSITORY}/compare/#{SHA}...release/0.3 --jq .status".freeze

  def verify(responses, *tags)
    Dir.mktmpdir do |directory|
      calls_path = File.join(directory, "calls")
      File.write(calls_path, "")
      gh_path = File.join(directory, "gh")
      cases = responses.map do |command, output|
        result = output ? "printf '%s\\n' #{Shellwords.escape(output)}" : "echo 'API request failed' >&2; exit 1"
        "#{Shellwords.escape(command)}) #{result} ;;"
      end
      File.write(gh_path, [
        "#!/bin/sh",
        'printf "%s\\n" "$*" >>"$GH_CALLS"',
        'case "$*" in',
        *cases,
        '*) echo "Unexpected API call: $*" >&2; exit 1 ;;',
        "esac",
      ].join("\n"))
      File.chmod(0755, gh_path)

      stdout, stderr, status = Open3.capture3(
        { "PATH" => "#{directory}:#{ENV.fetch("PATH")}", "GH_CALLS" => calls_path },
        "bash", SCRIPT, *tags
      )
      return stdout, stderr, status, File.readlines(calls_path, chomp: true)
    end
  end

  def test_accepts_tags_on_main_without_requiring_a_maintenance_branch
    %w[ahead identical].each do |comparison|
      stdout, stderr, status, calls = verify(
        { TAG_COMMAND => SHA, MAIN_COMMAND => comparison }, "v0.3.1"
      )
      assert status.success?, stderr
      assert_equal "main\n", stdout
      assert_equal [TAG_COMMAND, MAIN_COMMAND], calls
    end
  end

  def test_accepts_tags_only_on_the_matching_maintenance_branch
    %w[behind diverged].product(%w[ahead identical]).each do |main, maintenance|
      stdout, stderr, status, calls = verify(
        { TAG_COMMAND => SHA, MAIN_COMMAND => main, MAINTENANCE_COMMAND => maintenance }, "v0.3.1"
      )
      assert status.success?, stderr
      assert_equal "release/0.3\n", stdout
      assert_equal [TAG_COMMAND, MAIN_COMMAND, MAINTENANCE_COMMAND], calls
    end
  end

  def test_rejects_tags_not_contained_in_either_allowed_branch
    %w[behind diverged].each do |comparison|
      stdout, stderr, status, calls = verify(
        { TAG_COMMAND => SHA, MAIN_COMMAND => "diverged", MAINTENANCE_COMMAND => comparison }, "v0.3.1"
      )
      refute status.success?
      assert_empty stdout
      assert_includes stderr, "not on upstream main or release/0.3"
      assert_equal [TAG_COMMAND, MAIN_COMMAND, MAINTENANCE_COMMAND], calls
    end
  end

  def test_derives_the_maintenance_branch_from_the_tag
    tag_command = "api #{REPOSITORY}/commits/refs/tags/v12.34.56 --jq .sha"
    branch_command = "api #{REPOSITORY}/compare/#{SHA}...release/12.34 --jq .status"
    stdout, stderr, status, calls = verify(
      { tag_command => SHA, MAIN_COMMAND => "diverged", branch_command => "identical" }, "v12.34.56"
    )
    assert status.success?, stderr
    assert_equal "release/12.34\n", stdout
    assert_equal [tag_command, MAIN_COMMAND, branch_command], calls
  end

  def test_rejects_missing_maintenance_branch_or_failed_comparison
    stdout, stderr, status, = verify(
      { TAG_COMMAND => SHA, MAIN_COMMAND => "diverged", MAINTENANCE_COMMAND => nil }, "v0.3.1"
    )
    refute status.success?
    assert_empty stdout
    assert_includes stderr, "API request failed"
  end

  def test_does_not_fall_back_when_main_comparison_fails
    stdout, stderr, status, calls = verify(
      { TAG_COMMAND => SHA, MAIN_COMMAND => nil, MAINTENANCE_COMMAND => "identical" }, "v0.3.1"
    )
    refute status.success?
    assert_empty stdout
    assert_includes stderr, "API request failed"
    assert_equal [TAG_COMMAND, MAIN_COMMAND], calls
  end

  def test_rejects_failed_tag_lookup
    stdout, stderr, status, calls = verify({ TAG_COMMAND => nil }, "v0.3.1")
    refute status.success?
    assert_empty stdout
    assert_includes stderr, "API request failed"
    assert_equal [TAG_COMMAND], calls
  end

  def test_rejects_unexpected_comparison_status
    stdout, stderr, status, calls = verify(
      { TAG_COMMAND => SHA, MAIN_COMMAND => "null", MAINTENANCE_COMMAND => "identical" }, "v0.3.1"
    )
    refute status.success?
    assert_empty stdout
    assert_includes stderr, "Unexpected comparison status"
    assert_equal [TAG_COMMAND, MAIN_COMMAND], calls
  end

  def test_rejects_invalid_tags_before_calling_github
    [[], ["v0.3.1", "main"], ["0.3.1"], ["v0.3.1-rc.1"], ["v0.3.1\n"], ["v0.3.1/../../main"]].each do |tags|
      stdout, stderr, status, calls = verify({}, *tags)
      refute status.success?
      assert_empty stdout
      assert_includes stderr, "usage:"
      assert_empty calls
    end
  end
end
