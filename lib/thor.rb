require_relative 'thor/collector'
require 'optparse'

# --------------------------------------------------------
# Parse command line
# --------------------------------------------------------
options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: thor.rb [options]'
  opts.on('-e', '--exchange NAME', 'name of the Exchange (MOEX or SPBEX)') do |exchange|
    options[:exchange] = exchange
  end
  opts.on('-o', '--output FILE', 'save report to FILE (in Excel 97 format') do |file|
    options[:output] = file
  end
  opts.on('-v', '--verbose', 'run with debug logging') do |v|
    options[:verbose] = v
  end
  opts.on('-h', '--help', 'print this help message') do
    puts opts
    exit
  end
end.parse!

# Check the name of Exchange
if options[:exchange].nil?
  puts 'The name of Exchange is not specified'
  exit 1
end

# Set the output filename if not specified
options[:output] = "#{options[:exchange]}_#{Time.now.strftime('%Y%m%d')}.xls" unless options[:output]

# --------------------------------------------------------
# Setup logging
# --------------------------------------------------------
Logging.verbose if options[:verbose]

# --------------------------------------------------------
# Get list of tickers from requested Exchange
# --------------------------------------------------------
collector = Thor::Collector.new options[:exchange]
collector.save options[:output]
