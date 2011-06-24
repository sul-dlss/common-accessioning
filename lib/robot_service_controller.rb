require 'daemons'
require 'logger'

module LyberCore
  module Robots
    class ServiceController
      attr_reader :logger, :pid_dir

      def initialize(workflow, opts = {})
        @logger = opts[:logger] || Logger.new($stdout)
        @logger.level = opts[:log_level] || Logger::ERROR
        @pid_dir = opts[:pid_dir] || File.join(File.dirname(__FILE__), '../pid')
        @pid_dir = File.expand_path(pid_dir)
        @workflow = workflow
        @logger.debug "Initializing application group for #{@workflow}."
        @logger.debug "Writing pids to #{@pid_dir}"
        @group = Daemons::ApplicationGroup.new(workflow, :dir_mode => :normal, :dir => @pid_dir, :multiple => true)
        @yaml_file = File.join(@pid_dir, "#{@workflow}.yml")
      end

      def start(robot_name, &block)
        with_robot_info do
          result = false
          app = find_app(robot_name)
          if app.nil? or (app.running? == false)
            @logger.info "Starting #{@workflow}:#{robot_name}..."
            app, message = capture_stdout do
              new_app = @group.new_application({:mode => :proc, :proc => block})
              new_app.start
              new_app
            end
            if app.running?
              @logger.info "#{@workflow}:#{robot_name} [#{app.pid.pid}] started."
              @robots[robot_name] = app.pid.pid
              result = true
            else
              @logger.error "Unable to start #{@workflow}:#{robot_name}"
              @robots.delete(:robot_name)
            end
          else app.running?
            @logger.warn "Robot #{@workflow}:#{robot_name} [#{app.pid.pid}] is already running"
          end
          result
        end
      end
  
      def stop(robot_name)
        with_robot_info do
          app = find_app(robot_name)
          result = false
          if app.nil?
            @logger.info "Robot #{@workflow}:#{robot_name} not found"
          elsif app.running?
            @logger.info "Shutting down #{@workflow}:#{robot_name} [#{app.pid.pid}]..."
            result, message = capture_stdout { app.stop }
            if not app.running?
              @logger.info "#{@workflow}:#{robot_name} [#{app.pid.pid}] shut down."
              @robots.delete(robot_name)
              result = true
            else
              @logger.error "Unable to stop #{@workflow}:#{robot_name} [#{app.pid.pid}]."
            end
          else
            @logger.warn "Robot #{@workflow}:#{robot_name} [#{app.pid.pid}] is not running but pidfile exists"
            @robots.delete(robot_name)
          end
          result
        end
      end
  
      def status(robot_name)
        with_robot_info do
          app = find_app(robot_name)
          result = { :status => nil, :pid => nil }
          unless app.nil?
            result[:pid] = app.pid.pid
            result[:status] = app.running? ? :running : :stopped
          end
          result
        end
      end
  
      def status_message(robot_name)
        app_status = status(robot_name)
        message = case app_status[:status]
        when :running
          "Robot #{@workflow}:#{robot_name} [#{app_status[:pid]}] is running"
        when :stopped
          "Robot #{@workflow}:#{robot_name} [#{app_status[:pid]}] is not running but pidfile exists"
        else
          "Robot #{@workflow}:#{robot_name} not found"
        end
        return message
      end
  
      private
      def capture_stdout
        old_io = $stdout
        begin
          new_io = StringIO.new('')
          $stdout = new_io
          result = yield
          @logger.debug new_io.string
          return result, new_io.string
        ensure
          $stdout = old_io
        end
      end
  
      def with_robot_info
        result = begin
          load_robot_info
          yield
        ensure
          save_robot_info
        end
        return result
      end
  
      def find_app(robot_name)
        with_robot_info { @group.find_applications_by_app_name(@workflow).find { |a| a.pid.pid == @robots[robot_name] } }
      end
  
      def load_robot_info
        if File.exists?(@yaml_file)
          @robots = YAML.load(File.read(@yaml_file))
          @logger.debug "Loaded pids #{@robots.inspect} from #{@yaml_file}"
        else
          @logger.debug "Creating new pid hash"
          @robots = {}
        end
      end
  
      def save_robot_info
        @logger.debug "Saving pids #{@robots.inspect} to #{@yaml_file}"
        File.open(@yaml_file, 'w') { |f| YAML.dump(@robots, f) }
      end
    end
  end
end