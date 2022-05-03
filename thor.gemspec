Gem::Specification.new do |spec|
  spec.name = 'thor'
  spec.version = '0.9.0'
  spec.summary = 'Financial reconnaissance tool'
  spec.description = 'Enrich tickers from SPBEX/MOEX with information from YahooFinance'
  spec.required_ruby_version = '>= 3.0.0'
  spec.authors = ['ice']
  spec.email = 'ice.nightcrawler@gmail.com'
  spec.files = %w[
    lib/thor.rb
    lib/thor/collector.rb
    lib/thor/logging.rb
    lib/thor/report.rb
    lib/thor/tickers_cache.rb
    lib/thor/yahoo_finance.rb
  ]
  spec.homepage = 'https://ice-castle.ru'
  spec.license = 'MIT'
end
