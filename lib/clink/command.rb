require "clink"
require "optparse"
require "uri"

class Clink::Command
  attr_reader :server, :handler, :args, :opts
  attr_accessor :help

  def initialize(server, handler)
    @handler = handler
    @server = server
  end

  def execute(env)
    exec = Execution.new(self, env)
    server.helper_methods.each { |helper| exec.instance_eval(&helper) }
    exec.execute
  end

  def display_help(env)
    exec = Execution.new(self, env)
    exec.display_help
  end

  class Execution
    attr_reader :command, :env
    attr_reader :args, :opts

    def initialize(command, env)
      @command = command
      @env = env
      parse_args_and_opts
    end

    def execute
      catch(:done) do
        instance_eval &command.handler
      end
      finish if timers.length.zero?
    end

    def display_help
      puts command.help
      chunked_stream_close
    end

    def chunked_stream_send(chunk)
      return if chunk.empty?
      chunk_len_in_hex = chunk.bytesize.to_s(16)
      body = [chunk_len_in_hex, "\r\n", chunk, "\r\n"].join
      env.stream_send(body)
    end

    def chunked_stream_close
      env.stream_send([0, "\r\n", "\r\n"].join)
      env.stream_close
    end

    def print(message="")
      chunked_stream_send URI.escape(message)
    end

    def puts(message="")
      print "#{message}\n"
    end

    def error(message)
      puts " !     #{message}"
      throw :done
    end

    def finish
      timers.each(&:cancel)
      chunked_stream_close
    end

    def timers
      @timers ||= []
    end

    def every(interval=1, &blk)
      timers << EM.add_periodic_timer(interval, &blk)
    end

    def delay(interval=1, &blk)
      timers << EM.add_periodic_timer(interval, &blk)
    end

    def meta(name, value)
      @meta ||= {}
      @meta[name] = value
    end

    def parse_args_and_opts
      @opts = {}
      @args = []

      invalid_options = []

      raw_args = (env.params["args"] || "").split(",").map { |arg| URI.unescape(arg) }

      parser = OptionParser.new do |parser|
        command.server.global_options.each do |global_option|
          parser.on(*global_option[:args]) do |value|
            @opts[global_option[:name]] = value
          end
        end
        # command[:options].each do |name, option|
        #   parser.on("-#{option[:short]}", "--#{option[:long]}", option[:desc]) do |value|
        #     opts[name.gsub("-", "_").to_sym] = value
        #   end
        # end
      end

      begin
        parser.order!(raw_args) do |nonopt|
          invalid_options << nonopt
        end
      rescue OptionParser::InvalidOption => ex
        invalid_options << ex.args.first
        retry
      end

      raise OptionParser::ParseError if opts[:help]

      @args.concat(invalid_options)

      @args = args
      @opts = opts

      # p [:args, @args]
      # p [:opts, @opts]
    end
  end
end
