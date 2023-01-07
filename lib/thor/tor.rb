require 'socket'

module Thor
  # Tor Control Protocol client
  class Tor
    include logging
    def initialize
      @socket = TCPSocket.new('127.0.0.1', 9051)
      @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
      @authenticated = false
      super
    end

    def connect
      close

      self
    end

    def close
      @socket.close
      @socket = nil
      self
    end

    private

    def send_line(line)
      @socket.write(line.to_s + '\r\n')
      @socket.flush
    end

    def read_reply
      @socket.read_line.chomp
    end

    def authenticate

    end

    def send_command(command, *args)
      send_line(["#{command.to_s.upcase}", *args].join(' '))
    end
  end
end
