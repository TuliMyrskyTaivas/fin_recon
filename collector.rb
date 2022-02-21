require_relative 'logging'
require_relative 'report'
require_relative 'tickers_cache'
require_relative 'yahoo_finance'

class Collector
  include Logging

  def initialize
    @cache = TickersCache.new
    @yahoo = YahooFinance.new
    @report = Report.new
  end

  def isin?(data)
    data.match?('[A-Z]{2}[0-9A-Z]{10}')
  end

  def get_ticker_from_yahoo(asset) # rubocop:disable Metrics/MethodLength
    @yahoo.search_by_name(asset)
  rescue RestClient::ExceptionWithResponse => e
    if e.http_code == 404
      logger.info 'Sleeping for 2 minutes to avoid license restriction on API'
      sleep 120
      logger.info 'Retrying search...'
      retry
    else
      logger.error "Wrong response #{e.http_code}: #{e.message}"
      raise YahooFinance::NotFound.new(name: asset)
    end
  end

  def search(firm) # rubocop:disable Metrics/MethodLength
    logger.info "looking for \"#{firm}\""
    begin
      ticker = @cache.find(firm)
      unless ticker
        yahoo = get_ticker_from_yahoo(firm)
        profile = @yahoo.asset_profile(yahoo.ticker)
        ticker = Ticker.new(name: yahoo.name, rts_code: yahoo.ticker, isin_code: isin?(firm) ? firm : nil,
                            country: profile.country, industry: profile.industry)
        logger.info "#{ticker.name}(#{ticker.rts_code}), #{profile.country}, #{profile.industry}"
        @cache.add ticker
      end
      stats = @yahoo.key_statistics(ticker.rts_code)

      @report.add ticker: ticker, stats: stats
    rescue YahooFinance::NotFound
      logger.warn "Not found ticker for #{firm}"
      @report.not_found name: firm
    rescue RestClient::ExceptionWithResponse => e
      logger.warn "Failed to acquire information on firm \"#{firm}\": " + e.message
      @report.not_found name: firm
    end
  end

  def search_list(filelist)
    File.open(filelist).each_line do |line|
      search(line.strip)
    end
  end

  def save(filename)
    @report.write filename
  end
end
