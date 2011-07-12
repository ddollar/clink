require "clink"
require "clink/command"
require "goliath"

class Clink::Server < Goliath::API

  def self.inherited(base)
    base.use Goliath::Rack::Params
  end

  def self.commands
    @commands ||= {}
  end

  def self.command(name, &block)
    command = Clink::Command.new(self, block)
    command.help = extract_help_from_caller(caller.first)
    commands[name] = command
  end

  def self.helper_methods(&block)
    @helpers = [[], @helpers, block].flatten.compact
  end

  def self.global_options
    @global_options ||= []
  end

  def self.global_option(name, *args)
    global_options << { :name => name, :args => args }
  end

  #
  # Parse the caller format and identify the file and line number as identified
  # in : http://www.ruby-doc.org/core/classes/Kernel.html#M001397.  This will
  # look for a colon followed by a digit as the delimiter.  The biggest
  # complication is windows paths, which have a color after the drive letter.
  # This regex will match paths as anything from the beginning to a colon
  # directly followed by a number (the line number).
  #
  # Examples of the caller format :
  # * c:/Ruby192/lib/.../lib/heroku/command/addons.rb:8:in `<module:Command>'
  # * c:/Ruby192/lib/.../heroku-2.0.1/lib/heroku/command/pg.rb:96:in `<class:Pg>'
  # * /Users/ph7/...../xray-1.1/lib/xray/thread_dump_signal_handler.rb:9
  #
  def self.extract_help_from_caller(line)
    # pull out of the caller the information for the file path and line number
    if line =~ /^(.+?):(\d+)/
      return extract_help($1, $2)
    end
    raise "unable to extract help from caller: #{line}"
  end

  def self.extract_help(file, line)
    buffer = []
    lines  = File.read(file).split("\n")

    catch(:done) do
      (line.to_i-2).downto(0) do |i|
        case lines[i].strip[0..0]
          when "", "#" then buffer << lines[i]
          else throw(:done)
        end
      end
    end

    buffer.map! do |line|
      line.strip.gsub(/^#/, "")
    end

    buffer.reverse.join("\n").strip
  end

  def response(env)
    EM.defer do
      begin
        if command = command_from_request_path(env)
          case env["REQUEST_METHOD"]
            when "GET"  then command.display_help(env)
            when "POST" then command.execute(env)
          end
        end
      rescue Exception => ex
        puts ex.message
        puts ex.backtrace
        env.stream_close rescue nil
      end
    end
    [ 200, { "Transfer-Encoding" => "chunked" }, Goliath::Response::STREAMING ]
  end

  def command_from_request_path(env)
    command_paths = env["REQUEST_PATH"].split("/")
    command_paths.shift
    self.class.commands[command_paths.join(":")]
  end

end
