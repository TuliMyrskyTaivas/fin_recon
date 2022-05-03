require 'optparse'
require 'open-uri'

module Thor
  class SpbExchange
    include Logging

    attr_reader :assets

    def initialize
      @assets = []
      URI.open('https://spbexchange.ru/ru/listing/securities/list/?csv=download') do |data|
        data.each do |line|
          fields = line.split(';')
          if fields.size < 7
            logger.error "Invalid line SPBEXNG response: #{line}"
            next
          end
          # search by isin_code if not empty
          @assets.append(fields[7]) unless fields[7].empty?
        end
      end
      logger.info "#{@assets.size} assets exist on SpbExchange"
    end
  end
end