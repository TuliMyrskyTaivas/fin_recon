require_relative 'collector'
require_relative 'logging'
require 'spreadsheet'
require 'optparse'

# --------------------------------------------------------
# Process command line options
# --------------------------------------------------------
options = {
  output: 'report.xls'
}
OptionParser.new do |opts|
  opts.banner = 'Usage: fin_recon.rb [options]'
  opts.on('-f', '--filelist FILE', 'search for the firms listed in FILE') do |file|
    options[:firms] = file
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

# --------------------------------------------------------
# Setup logging
# --------------------------------------------------------
Logging.verbose if options[:verbose]

# --------------------------------------------------------
# Main logic
# --------------------------------------------------------
collector = Collector.new
collector.search_list options[:firms]
collector.save options[:output]
