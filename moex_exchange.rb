# --------------------------------------------------------
# Produce a report about tickers available on MoexExchange
# --------------------------------------------------------
require_relative 'tickers_cache'
require_relative 'collector'
require_relative 'logging'
require 'rest-client'
require 'optparse'

class MoexExchange
  include Logging

  attr_reader :assets

  def initialize
    @assets = []
    response = RestClient.get('https://iss.moex.com/iss/engines/stock/markets/shares/boards/TQBR/securities.json?iss.meta=off&securities.columns=ISIN')
    JSON.parse(response.body)['securities']['data'].each do |asset|
      assets.append(asset[0])
    end
    logger.info "#{@assets.size} assets exist on MOEX Exchange"
  end
end

# --------------------------------------------------------
# Parse command line
# --------------------------------------------------------
options = {
  output: "moex_exchange_#{Time.now.strftime('%Y%m%d')}.xls"
}
OptionParser.new do |opts|
  opts.banner = 'Usage: moex_exchange.rb [options]'
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
MoexExchange.new.assets.each do |asset|
  collector.search asset
end
collector.save options[:output]
