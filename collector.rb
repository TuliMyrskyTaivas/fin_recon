require_relative 'logging'
require_relative 'report'
require_relative 'yahoo_finance'

class Collector
  include Logging

  def initialize
    @yahoo = YahooFinance.new
    @report = Report.new
  end

  def search(filelist)
    count = 0
    File.open(filelist).each_line do |line|
      firm = line.strip
      logger.info "looking for \"#{firm}\""
      begin
        ticker = @yahoo.search_by_name(firm)
        profile = @yahoo.asset_profile(ticker.ticker)
        stats = @yahoo.key_statistics(ticker.ticker)
        logger.info "#{ticker.ticker}, #{ticker.name}, #{profile.country}, #{profile.industry}"
        @report.add ticker: ticker, profile: profile, stats: stats
      rescue YahooFinance::NotFound
        logger.warn "Firm \"#{firm}\" was not found"
        @report.not_found name: firm
      rescue RestClient::ExceptionWithResponse => e
        logger.warn "Failed to acquire information on firm \"#{firm}\": " + e.message
        @report.not_found name: firm
      end

      count += 1
      next unless count > 50

      logger.info 'Sleeping for 2 minutes to avoid license restriction on API'
      sleep 120
      count = 0
    end
  end

  def save(filename)
    @report.write filename
  end
end
