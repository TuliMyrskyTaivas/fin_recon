require_relative 'logging'
require 'sqlite3'

module Thor
  # Data structure to represent a single ticker
  class Ticker
    attr_reader :name, :source, :isin_code, :rts_code, :country, :industry

    def initialize(name:, source:, isin_code:, rts_code:, country:, industry:)
      @name = name
      @source = source
      @isin_code = isin_code
      @rts_code = rts_code
      @country = country
      @industry = industry
    end
  end

  # Database backend to store basic information about tickers/ISINs
  class TickersCache
    include Thor::Logging

    def initialize
      @db = SQLite3::Database.new 'cache.db'
      create_tables
      create_indices
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

      ticker = Ticker.new(name: result[1], source: result[2], isin_code: result[3], rts_code: result[4],
                          country: result[5], industry: result[6])
      logger.debug "'#{data}' found in the cache: RTS:#{ticker.rts_code}, ISIN:#{ticker.isin_code}"
      ticker
    end

    def add(ticker)
      logger.debug "Adding #{ticker.name} (#{ticker.rts_code}) to the cache..."
      query = <<-SQL
      INSERT INTO tickers (company_name, source, isin_code, rts_code, country, industry) VALUES (?, ?, ?, ?, ?, ?);
      SQL
      @db.execute query, ticker.name, ticker.source, ticker.isin_code, ticker.rts_code, ticker.country, ticker.industry
    end

    def save_stats(ticker:, stats:)
      logger.debug "Adding statistics on #{ticker.name} to the cache..."
      query = <<-SQL
      INSERT OR REPLACE INTO stats (ticker_id, market_cap, price, pe_ratio, eps, div_yield, updated)
      VALUES ((SELECT id FROM tickers where rts_code = ?), ?, ?, ?, ?, ?, CURRENT_TIMESTAMP);
      SQL
      @db.execute query, ticker.rts_code, stats.market_cap, stats.price, stats.pe_ratio, stats.eps, stats.dividend_yield
    end

    def get_report
      query = <<-SQL
      SELECT rts_code, source, company_name, country, industry, market_cap, price, pe_ratio, eps, div_yield
      FROM tickers INNER JOIN stats on stats.ticker_id = tickers.id
      ORDER BY country ASC, industry ASC, div_yield DESC;
      SQL
      @db.execute query
    end

    private

    def create_tables
      @db.execute <<-SQL
        CREATE TABLE IF NOT EXISTS tickers(
          id INTEGER PRIMARY KEY,
          company_name TEXT NOT NULL,
          source TEXT NOT NULL,
          isin_code TEXT UNIQUE,
          rts_code TEXT UNIQUE,
          country TEXT,
          industry TEXT
        );
      SQL
      @db.execute <<-SQL
        CREATE TABLE IF NOT EXISTS stats(
          id INTEGER PRIMARY KEY,
          ticker_id INTEGER NOT NULL UNIQUE,
          market_cap INTEGER,
          price INTEGER,
          pe_ratio INTEGER,
          eps INTEGER,
          div_yield INTEGER,
          updated TEXT NOT NULL,
          FOREIGN KEY (ticker_id) REFERENCES tickers(id)
        );
      SQL
    end

    def create_indices
      @db.execute <<-SQL
        CREATE INDEX IF NOT EXISTS isin_idx ON tickers(
          "isin_code"	ASC
        );
      SQL
      @db.execute <<-SQL
        CREATE INDEX IF NOT EXISTS rts_idx ON tickers(
          "rts_code"	ASC
        );
      SQL
      @db.execute <<-SQL
        CREATE INDEX IF NOT EXISTS company_idx ON tickers(
          "company_name"	ASC
        );
      SQL
    end
  end
end
