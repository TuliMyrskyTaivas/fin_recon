require 'logger'

module Thor
  module Logging
    # Use a hash class-ivar to cache a unique Logger per class
    @loggers = {}
    @severity = Logger::INFO

    def logger
      @logger ||= Logging.logger_for(self.class.name)
    end

    def verbose
      @severity = Logger::DEBUG
      @loggers.each_value do |logger|
        logger.level = @severity
      end
    end
    module_function :verbose

    class << self
      def logger_for(classname)
        @loggers[classname] ||= configure_logger_for(classname)
      end

      def configure_logger_for(classname)
        logger = Logger.new(STDOUT)
        logger.level = @severity
        logger.progname = classname
        logger.datetime_format = '%Y-%m-%d %H:%M:%S'
        logger.formatter = proc do |_severity, datetime, progname, msg|
          "#{datetime} #{progname}: #{msg}\n"
        end
        logger
      end
    end
  end
end
