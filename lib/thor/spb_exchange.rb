require 'open-uri'

module Thor
  # Get list of equities from SpbExchange
  class SpbExchange
    include Logging

    attr_reader :assets, :source

    def initialize
      @assets = []
      @source = 'SpbEx'
      url = 'https://spbexchange.ru/ru/listing/securities/list/?csv=download'
      URI.open(url, 'User-Agent' => 'curl/7.76.0') do |data|
        data.each do |line|
          fields = line.split(';')
          if fields.size < 7
            logger.error "Invalid line in SPBEX response: #{line}"
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