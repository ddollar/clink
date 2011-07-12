require "clink"
require "net/http"
require "uri"

class Clink::Client

  attr_reader :server
  attr_accessor :input, :output

  def initialize(server)
    @server = URI.parse(server)
    @input  = $stdin
    @output = $stdout
  end

  def execute(args)
    command = (args.shift || "help").split(":").join("/")

    if args.include?("--help")
      help(command)
    else
      run(command, args)
    end
  end

private

  def help(command)
    print "Usage: heroku "
    get command
    puts
  end

  def run(command, args)
    post command, args.map { |arg| URI.escape(arg) }.join(",")
  end

  def display_chunk(chunk)
    output.print URI.unescape(chunk)
  end

  def get(path)
    Net::HTTP.start(server.host, server.port) do |http|
      http.request(Net::HTTP::Get.new("/#{path}")) do |response|
        response.read_body do |chunk|
          display_chunk(chunk)
        end
      end
    end
  end

  def post(path, body)
    Net::HTTP.start(server.host, server.port) do |http|
      request = Net::HTTP::Post.new("/#{path}")
      request.body = "args=#{body}"
      http.request(request) do |response|
        response.read_body do |chunk|
          display_chunk(chunk)
        end
      end
    end
  end

end
