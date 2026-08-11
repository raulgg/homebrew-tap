#!/usr/bin/env ruby
# typed: strict
# frozen_string_literal: true

require "rubygems/version"

tag, checksum = ARGV

abort "usage: #{File.basename($PROGRAM_NAME)} vVERSION SHA256" if ARGV.length != 2
abort "invalid release tag: #{tag}" unless tag.match?(/\Av\d+\.\d+\.\d+\z/)
abort "invalid SHA-256: #{checksum}" unless checksum.match?(/\A[0-9a-f]{64}\z/)

formula_path = ENV.fetch(
  "AIRPODS_CONTROL_FORMULA_PATH",
  File.expand_path("../Formula/airpods-control.rb", __dir__),
)
formula = File.read(formula_path)
url_pattern = %r{^  url "https://github\.com/raulgg/airpods-control/archive/refs/tags/v(\d+\.\d+\.\d+)\.tar\.gz"$}
checksum_pattern = /^  sha256 "[0-9a-f]{64}"$/

abort "expected one airpods-control URL" unless formula.scan(url_pattern).one?
abort "expected one airpods-control checksum" unless formula.scan(checksum_pattern).one?

current_version = Gem::Version.new(formula.match(url_pattern)[1])
current_checksum = formula.match(checksum_pattern)[0][/"([0-9a-f]{64})"/, 1]
release_version = Gem::Version.new(tag.delete_prefix("v"))

# Updates are monotonic; retries may no-op, but an existing version's checksum is immutable.
if release_version < current_version
  abort "refusing downgrade from v#{current_version} to #{tag}"
end

if release_version == current_version
  if checksum != current_checksum
    abort "refusing changed archive checksum for existing #{tag}"
  end

  puts "Formula already references #{tag} with the expected checksum"
  exit 0
end

release_url = "https://github.com/raulgg/airpods-control/archive/refs/tags/#{tag}.tar.gz"
updated = formula.sub(url_pattern, "  url \"#{release_url}\"")
                 .sub(checksum_pattern, "  sha256 \"#{checksum}\"")

File.write(formula_path, updated)
puts "Updated Formula/airpods-control.rb to #{tag}"
