require 'roo'
require 'open-uri'

module Thor
  # Get list of equities from Hong-Kong Exchange
  class HkexExchange
    include Logging

    attr_reader :assets, :source

    def initialize
      @assets = []
      @source = 'HKEX'
      url = 'https://www.hkex.com.hk/eng/services/trading/securities/securitieslists/ListOfSecurities.xlsx'

      logger.info "Parsing list of securities from HKEX..."
      xlsx = Roo::Excelx.new(URI(url).open, { expand_merged_ranges: true })

      row_number = 0
      xlsx.sheet(0).each do |row|
        row_number += 1
        next if row_number < 4
        next unless row[2] == 'Equity'

        isin = row[6].strip
        @assets.append isin unless isin.empty?
      end
      logger.info "#{row_number - 4} assets exist on HKEX"
      super
    end
  end
end
