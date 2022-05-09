require_relative 'logging'
require 'rest-client'

module Thor
  # Receive stock shares (TQBR mode) from MOEX
  class MoexExchange
    include Logging

    attr_reader :assets, :source

    def initialize
      @assets = []
      @source = 'MOEX'
      response = RestClient.get('https://iss.moex.com/iss/engines/stock/markets/shares/boards/TQBR/securities.json?iss.meta=off&securities.columns=ISIN')
      JSON.parse(response.body)['securities']['data'].each do |asset|
        assets.append(asset[0])
      end
      logger.info "#{@assets.size} assets exist on MOEX Exchange"
    end
  end
end
