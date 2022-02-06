# --------------------------------------------------------
# Produce a report about tickers available on SpbExchange
# --------------------------------------------------------
require_relative 'collector'
require_relative 'logging'
require 'spreadsheet'
require 'optparse'
require 'open-uri'

class SpbAsset
  attr_reader :name, :isin_code, :rts_code

  def initialize(name:, isin_code:, rts_code:)
    @name = name
    @isin_code = isin_code
    @rts_code = rts_code
  end
end

class SpbExchange
  include Logging

  attr_reader :assets

  def initialize
    @assets = []
    URI.open('https://spbexchange.ru/ru/listing/securities/list/?csv=download') { |data|
      data.each { |line|
        fields = line.split(';')
        asset = SpbAsset.new(name: fields[2], rts_code: fields[6], isin_code: fields[7])
        @assets.append(asset)
      }
    }
    logger.info "#{@assets.size} asserts exists on SpbExchange"
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
spb.assets.each { |asset|
  collector.search asset.isin_code
}
collector.save options[:output]
