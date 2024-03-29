require_relative 'logging'
require 'rest-client'
require 'json'

module Thor
  #  Token description
  class Asset
    attr_reader :ticker, :exchange, :quote_type, :name

    def initialize(ticker:, exchange:, quote_type:, name:)
      @ticker = ticker
      @exchange = exchange
      @quote_type = quote_type
      @name = name
    end
  end

  #  Asset profile
  class AssetProfile
    attr_reader :country, :industry

    def initialize(country:, industry:)
      @country = country
      @industry = industry
    end
  end

  #  Key statistics
  class KeyStatistics
    attr_reader :pe_ratio, :price, :market_cap, :eps, :dividend_yield

    def initialize(price:, pe_ratio:, market_cap:, eps:, dividend_yield:)
      @pe_ratio = pe_ratio
      @price = price
      @market_cap = market_cap
      @eps = eps
      @dividend_yield = dividend_yield
    end
  end

  #  Request the data from Yahoo Finance service
  class YahooFinance
    include Logging

    class NotFound < StandardError
      def initialize(name:)
        super(msg: "not found token for #{name}")
      end
    end

    def search_by_name(name)
      logger.debug "Searching for \"#{name}\"..."
      response = RestClient.get('https://query1.finance.yahoo.com/v1/finance/search',
                                params: { q: name.to_s, quotesCount: 1, newsCount: 0, listsCount: 0,
                                          enableNavLinks: false })
      parsed = JSON.parse(response.body)
      raise NotFound.new(name: name) unless (parsed['count']).positive?

      quote = parsed['quotes'][0]
      Asset.new(ticker: quote['symbol'], exchange: quote['exchange'], quote_type: quote['quoteType'],
                name: quote['longname'])
    end

    def asset_profile(ticker)
      logger.debug "Requesting asset profile for #{ticker}..."
      response = RestClient.get("https://query1.finance.yahoo.com/v10/finance/quoteSummary/#{ticker}",
                                params: { modules: 'assetProfile' })
      parsed = JSON.parse(response.body)['quoteSummary']['result'][0]['assetProfile']
      AssetProfile.new(country: parsed['country'], industry: parsed['industry'])
    end

    def key_statistics(ticker)
      logger.debug "Requesting key statistics for #{ticker}..."
      response = RestClient.get("https://query1.finance.yahoo.com/v10/finance/quoteSummary/#{ticker}?modules=defaultKeyStatistics,price")
      begin
        parsed = JSON.parse(response.body)['quoteSummary']['result'][0]
        stats = parsed['defaultKeyStatistics']
        price = parsed['price']
        has_divs = !stats['lastDividendValue'].empty?
        eps = stats['forwardEps'].empty? ? '' : stats['forwardEps']['raw']
        KeyStatistics.new(pe_ratio: stats['forwardPE']['fmt'],
                          price: price['regularMarketPrice']['fmt'],
                          market_cap: price['marketCap']['fmt'],
                          eps: eps,
                          dividend_yield: has_divs ? (last_year_dividend(ticker) / price['regularMarketPrice']['raw'].to_f * 100).to_f.round(2) : '',
                         )
      rescue NoMethodError
        logger.error "Failed to parse Yahoo response: #{response.body}"
        raise
      end 
    end

    def last_year_dividend(ticker)
      logger.debug "Acquiring dividend history for #{ticker}..."
      start = 1_609_459_200 # Fri Jan 01 2021 00:00:00 GMT+0000
      stop = 1_640_980_800 # Fri Dec 31 2021 20:00:00 GMT+0000
      response = RestClient.get("https://query1.finance.yahoo.com/v8/finance/chart/#{ticker}",
                                params: { symbol: ticker, interval: '1mo', events: 'div', period1: start,
                                          period2: stop })
      parsed = JSON.parse(response.body)['chart']['result'][0]
      return 0 unless parsed.key?('events')

      result = 0.0
      parsed['events']['dividends'].each do |_timestamp, div|
        result += div['amount'].to_f
      end
      result
    end
  end
end
