require_relative 'logging'
require 'sqlite3'

class Ticker
  attr_reader :name, :isin_code, :rts_code, :country, :industry

  def initialize(name:, isin_code:, rts_code:, country:, industry:)
    @name = name
    @isin_code = isin_code
    @rts_code = rts_code
    @country = country
    @industry = industry
  end
end

class TickersCache
  include Logging

  def initialize
    @db = SQLite3::Database.new 'cache.db'
    @db.execute <<-SQL
        CREATE TABLE IF NOT EXISTS tickers(
          id INTEGER PRIMARY KEY,
          company_name TEXT,
          isin_code TEXT,
          rts_code TEXT,
          country TEXT,
          industry TEXT
        );
    SQL
    sqlite_version = @db.get_first_value 'SELECT SQLITE_VERSION()'
    cache_records = @db.get_first_value 'SELECT COUNT(*) FROM tickers'
    logger.info "Using SQLite/#{sqlite_version} as cache: #{@db.filename}"
    logger.info "Cache has #{cache_records} records"
    super
  rescue SQLite3::Exception => e
    logger.error "Failed to open cache: #{e.message}"
  end

  def find(data)
    logger.debug "Looking for '#{data}' in the cache..."
    result = @db.get_first_row 'SELECT * FROM tickers WHERE company_name=? OR isin_code=? OR rts_code=?',
                               data, data, data
    return nil unless result

    ticker = Ticker.new(name: result[1], isin_code: result[2], rts_code: result[3], country: result[4],
                        industry: result[5])
    logger.debug "'#{data}' found in the cache: RTS:#{ticker.rts_code}, ISIN:#{ticker.isin_code}"
    ticker
  end

  def add(ticker)
    logger.debug "Adding #{ticker.name} (#{ticker.rts_code}) to the cache..."
    query = <<-SQL
      INSERT INTO tickers (company_name, isin_code, rts_code, country, industry) VALUES (?, ?, ?, ?, ?);
    SQL
    @db.execute query, ticker.name, ticker.isin_code, ticker.rts_code, ticker.country, ticker.industry
  end
end
