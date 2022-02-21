# --------------------------------------------------------
# Produce a report about tickers available on SpbExchange
# --------------------------------------------------------
require_relative 'tickers_cache'
require_relative 'collector'
require_relative 'logging'
require 'spreadsheet'
require 'optparse'
require 'open-uri'

class SpbExchange
  include Logging

  attr_reader :assets

  def initialize
    @assets = []
    URI.open('https://spbexchange.ru/ru/listing/securities/list/?csv=download') do |data|
      data.each do |line|
        fields = line.split(';')
        @assets.append(fields[7]) # search by isin_code
      end
    end
    logger.info "#{@assets.size} assets exists on SpbExchange"
  end
end

# --------------------------------------------------------
# Parse command line
# --------------------------------------------------------
options = {
  output: "spb_exchange_#{Time.now.strftime('%Y%m%d')}.xls"
}
OptionParser.new do |opts|
  opts.banner = 'Usage: spb_exchange.rb [options]'
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
# Get list of tickers from SPB Exchange
# --------------------------------------------------------
collector = Collector.new
spb = SpbExchange.new
spb.assets.each do |asset|
  collector.search asset
end
collector.save options[:output]
