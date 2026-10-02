#!/usr/bin/env ruby
# typed: strict
# frozen_string_literal: true

require "rubygems/version"

tag, checksum = ARGV

abort "usage: #{File.basename($PROGRAM_NAME)} vVERSION SHA256" if ARGV.length != 2
abort "invalid release tag: #{tag}" unless tag.match?(/\Av\d+\.\d+\.\d+\z/)
abort "invalid SHA-256: #{checksum}" unless checksum.match?(/\A[0-9a-f]{64}\z/)

formula_dir = ENV.fetch(
  "PODS_CONTROL_FORMULA_DIR",
  File.expand_path("../Formula", __dir__),
)
formula_names = ["pods-control.rb", "airpods-control.rb"]
paths = formula_names.map { |name| File.join(formula_dir, name) }
missing = paths.reject { |path| File.file?(path) }
abort "missing formula file: #{missing.join(", ")}" unless missing.empty?

url_pattern = %r{^  url "https://github\.com/raulgg/pods-control/archive/refs/tags/v(\d+\.\d+\.\d+)\.tar\.gz"$}
checksum_pattern = /^  sha256 "[0-9a-f]{64}"$/

contents = paths.map { |path| File.read(path) }
parsed = contents.map do |formula|
  abort "expected one pods-control URL" unless formula.scan(url_pattern).one?
  abort "expected one pods-control checksum" unless formula.scan(checksum_pattern).one?

  version = Gem::Version.new(formula.match(url_pattern)[1])
  current_checksum = formula.match(checksum_pattern)[0][/"([0-9a-f]{64})"/, 1]
  [version, current_checksum]
end

if !parsed.map(&:first).uniq.one? || !parsed.map(&:last).uniq.one?
  details = paths.zip(parsed).map do |path, (version, current_checksum)|
    "#{File.basename(path)} v#{version} #{current_checksum}"
  end
  abort "formulae disagree on version or checksum: #{details.join("; ")}"
end

current_version, current_checksum = parsed.fetch(0)
release_version = Gem::Version.new(tag.delete_prefix("v"))

# Updates are monotonic; retries may no-op, but an existing version's checksum is immutable.
if release_version < current_version
  abort "refusing downgrade from v#{current_version} to #{tag}"
end

if release_version == current_version
  if checksum != current_checksum
    abort "refusing changed archive checksum for existing #{tag}"
  end

  puts "Formulae already reference #{tag} with the expected checksum"
  exit 0
end

release_url = "https://github.com/raulgg/pods-control/archive/refs/tags/#{tag}.tar.gz"
updated = contents.map do |formula|
  formula.sub(url_pattern, "  url \"#{release_url}\"")
         .sub(checksum_pattern, "  sha256 \"#{checksum}\"")
end

paths.zip(updated) do |path, body|
  File.write(path, body)
end
puts "Updated Formula/pods-control.rb and Formula/airpods-control.rb to #{tag}"
