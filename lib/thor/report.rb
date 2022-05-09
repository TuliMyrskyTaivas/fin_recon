require_relative 'logging'
require 'spreadsheet'

module Thor
  # Produce the report on the specified instruments
  class Report
    def initialize
      @report = Spreadsheet::Workbook.new
      @work_sheet = @report.create_worksheet name: 'Tickers'
      @errors_sheet = @report.create_worksheet name: 'Not found'
      @work_offset = 1
      @errors_offset = 1

      @work_sheet.row(0).default_format = Spreadsheet::Format.new color: :blue, weight: :bold, size: 10
      @work_sheet.row(0).replace ['Ticker', 'Exchange', 'Name', 'Country', 'Industry', 'Market cap', 'Price', 'P/E',
                                  'EPS', 'Dividend yield']
    end

    def build(report:)
      report.each do |row|
        @work_sheet.row(@work_offset).replace [row[0],
                                               row[1],
                                               row[2],
                                               row[3],
                                               row[4],
                                               row[5],
                                               row[6],
                                               row[7],
                                               row[8],
                                               row[9]]
        @work_offset += 1
      end
    end

    def not_found(name:)
      @errors_sheet.row(@errors_offset).replace [name]
      @errors_offset += 1
    end

    def write(filename)
      @report.write filename
    end
  end
end
