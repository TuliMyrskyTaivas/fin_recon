require 'caxlsx'

module Thor
  # Produce the report on the specified instruments
  class Report
    include Thor::Logging

    def initialize
      @report = Axlsx::Package.new author: 'Thor: financial reconnaissance tool'
      # Create sheets
      @work_sheet = @report.workbook.add_worksheet name: 'Tickers'
      @errors_sheet = @report.workbook.add_worksheet name: 'Not found'
      # Create styles
      @report.workbook.styles do |s|
        @header_style = s.add_style bg_color: '0000FF', fg_color: 'FF', sz: 10,
                                    alignment: { horizontal: :center }
      end


      @work_sheet.add_row ['Ticker', 'Exchange', 'Name', 'Country', 'Industry', 'Market cap', 'Price', 'P/E',
                           'EPS', 'Dividend yield'], style: @header_style
    end

    def build(report:)
      report.each do |row|
        @work_sheet.add_row [
          row[0], row[1], row[2], row[3], row[4],
          row[5], row[6], row[7], row[8], row[9]
        ]
      end
      @work_sheet.column_widths 10, 8, nil, 20, nil, 10, 10, 10, 10
    end

    def not_found(name:)
      @errors_sheet.add_row [name]
    end

    def write(filename)
      logger.info "Saving report to #{filename}"
      File.delete(filename) if File.exist?(filename)
      @report.serialize filename
    end
  end
end
