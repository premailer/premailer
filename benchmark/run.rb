# frozen_string_literal: true

# Times premailer on the real-world emails in benchmark/emails (see benchmark/README.md):
#
#   bundle exec rake benchmark [RUNS=20] [ADAPTER=nokogiri] [EMAIL=foundation]
#
# Prints, for each email, the median time and the objects allocated by Premailer.new (reading the
# HTML and its CSS), then by #to_inline_css and #to_plain_text, each called on a premailer already built.

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'premailer'

runs = Integer(ENV.fetch('RUNS', 20))
abort 'RUNS must be at least 1' unless runs > 0
adapter = ENV.fetch('ADAPTER', 'nokogiri').to_sym
filter = Regexp.new(ENV.fetch('EMAIL', ''))
emails = Dir[File.join(__dir__, 'emails', '*.html')].select { |path| File.basename(path).match?(filter) }

# Median time in ms of the block over runs calls, each given a fresh subject, then the objects one call allocates.
def measure(runs, subject)
  times = Array.new(runs) do
    given = subject.call
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield given
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
  end
  given = subject.call
  allocated = GC.stat(:total_allocated_objects)
  yield given
  [(times.sort[runs / 2] * 1000).round(2), GC.stat(:total_allocated_objects) - allocated]
end

def row(*columns)
  puts [columns.first.ljust(36), *columns.drop(1).map { |column| column.to_s.rjust(11) }].join
end

puts "premailer #{Premailer::VERSION}, #{adapter} adapter, #{RUBY_DESCRIPTION}, median of #{runs} runs"
row('email', 'new ms', 'objects', 'inline ms', 'objects', 'text ms', 'objects')
totals = Array.new(6, 0)
emails.each do |path|
  build = -> { Premailer.new(path, adapter: adapter, warn_level: Premailer::Warnings::NONE) }
  build.call.to_inline_css # warm up
  build.call.to_plain_text
  measurements = measure(runs, -> { path }) { build.call } +
                 measure(runs, build, &:to_inline_css) +
                 measure(runs, build, &:to_plain_text)
  totals = totals.zip(measurements).map(&:sum)
  row(File.basename(path), *measurements)
end
row('total', *totals.map { |total| total.round(2) })
