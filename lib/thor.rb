require_relative 'thor/collector'
require 'optparse'

# --------------------------------------------------------
# Parse command line
# --------------------------------------------------------
options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: thor.rb [options]'
  opts.on('-e', '--exchange NAME', 'enrich the data from specified Exchange (MOEX,SPBEX,HKEX)') do |exchange|
    options[:exchange] = exchange
  end
  opts.on('-o', '--output FILE', 'save report to FILE (in Excel 97 format)') do |file|
    options[:output] = file
  end
  opts.on('-n', '--new-only', 'request information on previously unknown tickers/firms only') do |only_new|
    options[:only_new] = only_new
  end
  opts.on('-r', '--dry-run', 'just build the report over the existing database') do |r|
    options[:report] = r
  end
  opts.on('-v', '--verbose', 'run with debug logging') do |v|
    options[:verbose] = v
  end
  opts.on('-h', '--help', 'print this help message') do
    puts opts
    exit
  end
end.parse!

# Set the output filename if not specified
options[:output] = "thor_report_#{Time.now.strftime('%Y%m%d')}.xls" unless options[:output]

# --------------------------------------------------------
# Setup logging
# --------------------------------------------------------
Thor::Logging.verbose if options[:verbose]

# --------------------------------------------------------
# Get list of tickers from requested Exchange
# --------------------------------------------------------
collector = Thor::Collector.new
collector.enrich(exchange: options[:exchange], only_new: options[:only_new]) unless options[:report]
collector.save options[:output]
