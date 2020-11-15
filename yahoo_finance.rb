require 'RestClient'
require 'json'

require_relative 'logging'

# ---------------------------------------------------------
#  Token description
# ---------------------------------------------------------
class Ticker
  attr_reader :ticker
  attr_reader :exchange
  attr_reader :quote_type
  attr_reader :name
  def initialize(ticker:, exchange:, quote_type:, name:)
    @ticker = ticker
    @exchange = exchange
    @quote_type = quote_type
    @name = name
  end
end

# ---------------------------------------------------------
#  Asset profile
# ---------------------------------------------------------
class AssetProfile
  attr_reader :country
  attr_reader :industry

  def initialize(country:, industry:)
    @country = country
    @industry = industry
  end
end

# ---------------------------------------------------------
#  Key statistics
# ---------------------------------------------------------
class KeyStatistics
  attr_reader :pe_ratio
  attr_reader :price
  attr_reader :market_cap
  attr_reader :dividend_yield
  attr_reader :last_dividend_value
  attr_reader :last_dividend_date

  def initialize(price:, pe_ratio:, market_cap:, dividend_yield:, last_div_value:, last_div_date:)
    @pe_ratio = pe_ratio
    @price = price
    @market_cap = market_cap
    @dividend_yield = dividend_yield
    @last_dividend_date = last_div_date
    @last_dividend_value = last_div_value
  end
end

# ---------------------------------------------------------
#  Main class
# ---------------------------------------------------------
class YahooFinance
  include Logging

  class NotFound < StandardError
    def initialize(name:)
      super(msg: "not found token for #{name}")
    end
  end

  def search_by_name(name)
    logger.debug "Searching for \"#{name}\"..."
    response = RestClient.get("https://query1.finance.yahoo.com/v1/finance/search",
                              params: {q: "#{name}", quotesCount: 1, newsCount: 0, listsCount: 0, enableNavLinks: false })
    parsed = JSON.parse(response.body)
    raise NotFound.new(name: name) unless parsed["count"] > 0

    quote = parsed["quotes"][0]
    Ticker.new(ticker: quote["symbol"], exchange: quote["exchange"], quote_type: quote["quoteType"], name: quote["longname"])
  end

  def asset_profile(ticker)
    logger.debug "Requesting asset profile for #{ticker}..."
    response = RestClient.get("https://query1.finance.yahoo.com/v10/finance/quoteSummary/#{ticker}",
                              params: {modules: "assetProfile"})
    parsed = JSON.parse(response.body)["quoteSummary"]["result"][0]["assetProfile"]
    AssetProfile.new(country: parsed["country"], industry: parsed["industry"])
  end

  def key_statistics(ticker)
    logger.debug "Requesting key statistics for #{ticker}..."
    response = RestClient.get("https://query1.finance.yahoo.com/v10/finance/quoteSummary/#{ticker}?modules=defaultKeyStatistics,price")
    parsed = JSON.parse(response.body)["quoteSummary"]["result"][0]
    stats = parsed["defaultKeyStatistics"]
    price = parsed["price"]
    has_divs = !stats["lastDividendValue"].empty?
    KeyStatistics.new(pe_ratio: stats["forwardPE"]["fmt"],
                      price: price["regularMarketPrice"]["fmt"],
                      market_cap: price["marketCap"]["fmt"],
                      dividend_yield: has_divs ? (last_year_dividend(ticker) / price["regularMarketPrice"]["fmt"].to_f * 100).to_f.round(2) : "",
                      last_div_date: has_divs ? stats["lastDividendDate"]["fmt"] : "",
                      last_div_value: has_divs ? stats["lastDividendValue"]["fmt"] : ""
                      )
  end

  def last_year_dividend(ticker)
    logger.debug "Acquiring dividend history for #{ticker}..."
    period2 = Time.now.to_i
    period1 = period2 - 31556952  # 31556952 seconds in one year
    response = RestClient.get("https://query1.finance.yahoo.com/v8/finance/chart/#{ticker}",
                              params: {symbol: ticker, interval: '1mo', events: 'div', period1: period1, period2: period2})
    parsed = JSON.parse(response.body)["chart"]["result"][0]
    return 0 unless parsed.has_key?("events")

    result = 0.0
    parsed["events"]["dividends"].each do | timestamp, div|
      result += div["amount"].to_f
    end
    result
  end
end