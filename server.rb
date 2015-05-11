require 'socket'
require 'thread'

class Server
  def initialize
    @port = 181818
    @server = TCPServer.new @port
    @rooms = []
    @rooms_num = 0
    @mutex = Mutex.new
    run
  end

  def run
   loop{
      client = @server.accept
      Thread.new do
        Thread.abort_on_exception =true
        puts "One client connects to the server!"
        handle(client)

      end
   }
  end

  def handle(client)
    loop{
      while  messageorigin = client.gets do
        message = messageorigin + get_rest_of_msg(messageorigin,client).to_s
        # puts message
        case message
          when /\AHELO/ then
            puts message
            ip = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address
            client.puts "#{message}IP: #{ip}\nPort: #{@port}\nStudent ID: 14306748\n"


        when /\AKILL_SERVICE\n\z/ then
            self.shutdown

          when /\AJOIN_CHATROOM:/ then
            puts message
            messageInput = ""
            messageInput = message.split("\n")
            roomname = messageInput[0].split(":")[1].strip
            cname = messageInput[3].split(":")[1].strip
          room,join_id = add_to_room(roomname,cname,client)
          send_join_notify_to_room(room,cname)
          ip = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address

            client.puts "JOINED_CHATROOM: #{room.name}\nSERVER_IP: #{ip}\nPORT: #{@port}\nROOM_REF: #{room.ref}\nJOIN_ID: #{join_id}\n"

          when /\ALEAVE_CHATROOM:/ then
            puts message
            messageInput = ""
            messageInput = message.split("\n")
            roomref = messageInput[0].split(":")[1].strip
            roomRef = roomref.to_i
            joinid = messageInput[1].split(":")[1].strip
            joinId = joinid.to_i
            cname = messageInput[2].split(":")[1].strip

            room = get_room_by_ref(roomRef)
            the_client = room.get_client(joinId,cname)
            if room == nil
              client.puts "ERROR_CODE: 001\nERROR_DESCRIPTION: Invalid ROOMREF\n"
            elsif the_client == nil
              client.puts "LEFT_CHATROOM: #{roomRef}\nJOIN_ID: #{joinId}\n"
            else
              remove_from_room(room,the_client)
              send_left_notify_to_room(room,the_client)
              client.puts "LEFT_CHATROOM: #{room.ref}\nJOIN_ID: #{the_client.join_id}\n"
            end


          when /\ADISCONNECT:0/ then
            puts message
            client.puts "Disconnect with server!"
            Thread.exit



          when /\ACHAT:/ then
            puts message
            messageInput = ""
            messageInput = message.split("\n")
            roomref = messageInput[0].split(":")[1].strip
            roomRef = roomref.to_i
            joinid = messageInput[1].split(":")[1].strip
            # joinId = joinid.to_i
            cname = messageInput[2].split(":")[1].strip
            cmsg = messageInput[3].split(":")[1].strip

        room = get_room_by_ref(roomRef)
        the_client = room.get_client(joinid,cname)
        if room == nil
          client.puts "ERROR_CODE: 001\nERROR_DESCRIPTION: Invalid ROOMREF\n"
        elsif the_client == nil
          client.puts "ERROR_CODE: 002\nERROR_DESCRIPTION: This user does not exist in the room\n"
        else

          send_msg_to_all_in_room(room,the_client,cmsg)
        end

        else
        client.puts "ERROR_CODE: 000\nERROR_DESCRIPTION: Invalid command\n"
      end
    end

    }
  end

  def get_rest_of_msg(messageorigin,client)
    case messageorigin
      when /\AJOIN_CHATROOM:/ then
        return client.gets+client.gets+client.gets
      when /\ACHAT:/ then
        return client.gets+client.gets+client.gets
      when /\ALEAVE_CHATROOM:/ then
        return client.gets+client.gets
      when /\ADISCONNECT:/ then
        return client.gets+client.gets
      else
        puts "message has only one line"
    end
  end

  def send_msg_to_all_in_room(room,client,message)
    room.clients.each do |current_client|
      current_client.connection.puts "CHAT: #{room.ref}\nCLIENT_NAME: #{client.name}\nMESSAGE: #{message}\n\n"
    end
  end

  def send_join_notify_to_room(room,name)
    room.clients.each do |current_client|
      current_client.connection.puts "#{name} joins ROOM #{room.ref}\n"
    end
  end

  def send_left_notify_to_room(room,name)
    room.clients.each do |current_client|
      current_client.connection.puts "#{name} leaves ROOM #{room.ref}\n"
    end
  end

  def get_room_by_name(name)
    @rooms.each do |room|
      return room if room.name == name
    end
    nil
  end

  def get_room_by_ref(ref)
    @rooms.each do |room|
      return room if room.ref == ref.to_i
    end
    nil
  end

  def add_to_room(room_name,client_name,client_connection)
    room = get_room_by_name(room_name)
    join_id = -1
    if room == nil
      @mutex.lock
      room = ChatRoom.new(room_name,@rooms_num)
      @rooms_num+=1
      @mutex.unlock
      @rooms << room
    end

    new_client = Client.new(client_name,room.num_clients,client_connection)
    room.mutex.lock
    join_id = room.num_clients
    room.num_clients+=1
    room.mutex.unlock
    room.clients << new_client

    return room, join_id
  end

  def remove_from_room(room,client)
    room.clients.delete(client)
  end

  def shutdown
    puts 'Server shutdown'
    @server.close
    Thread.list.each do |thread|
      thread.kill
    end
  end

end

class ChatRoom
  @num_clients
  @ref = nil
  @clients
  @name = nil
  @mutex

  attr_accessor :num_clients,:clients,:ref,:name,:mutex

  def initialize (name,ref)
    @name = name
    @ref = ref
    @clients = Array.new
    @num_clients = 0
    @mutex = Mutex.new
  end

  def get_client(join_id,name)
    @clients.each do |client|
      return client if client.name == name && client.join_id == join_id.to_i
    end
    nil
  end
end

class Client
  @name = nil
  @join_id = nil
  @connection = nil

  attr_accessor :name,:join_id,:connection

  def initialize(name,join_id,connection)
    @name = name
    @join_id = join_id
    @connection = connection
  end
end
Server.new
