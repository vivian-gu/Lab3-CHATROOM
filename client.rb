require 'socket'

class Client
  def initialize( server )
    @server = server
    @request = nil
    @response = nil
    listen
    send
    @request.join
    @response.join
  end

  def listen
    @response = Thread.new do
      loop {
        msg = @server.gets.chomp
        puts "#{msg}"

      }
    end
  end

  def send
    puts "Start sending requests!"
    @request = Thread.new do
      loop {
        msg = $stdin.gets
        @server.puts( msg )
      }
    end
  end
end

server = TCPSocket.open( "localhost", 181818 )
Client.new( server )

