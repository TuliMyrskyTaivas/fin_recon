require_relative 'logging'
require 'sqlite3'

module Thor
  # Data structure to represent a single ticker
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

    private

    def create_tables
      @db.execute <<-SQL
        CREATE TABLE IF NOT EXISTS tickers(
          id INTEGER PRIMARY KEY,
          company_name TEXT NOT NULL,
          isin_code TEXT UNIQUE,
          rts_code TEXT UNIQUE,
          country TEXT,
          industry TEXT
        );
      SQL
      @db.execute <<-SQL
        CREATE TABLE IF NOT EXISTS stats(
          id INTEGER PRIMARY KEY,
          ticker_id INTEGER NOT NULL,
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
