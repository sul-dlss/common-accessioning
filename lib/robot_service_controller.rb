require 'daemons'
require 'logger'

module LyberCore
  module Robots
    class ServiceController < Daemons::ApplicationGroup
      attr_reader :logger, :pid_dir

      def initialize(opts = {})
        @logger = opts[:logger] || Logger.new($stdout)
        @logger.level = opts[:log_level] || Logger::ERROR
        @working_dir = opts[:working_dir] || ENV['ROBOT_ROOT'] || Dir.pwd
        @pid_dir = opts[:pid_dir] || File.join(@working_dir, '../pid')
        @pid_dir = File.expand_path(pid_dir)
        @logger.debug "Initializing application group."
        @logger.debug "Writing pids to #{@pid_dir}"
        super('robot_service_controller', :dir_mode => :normal, :dir => @pid_dir, :multiple => true)
      end

      def start(workflow, robot_name)
        result = false
        app = find_app(workflow, robot_name).first
        if app.nil? or (app.running? == false)
          @logger.info "Starting #{workflow}:#{robot_name}..."
          with_app_name("#{workflow}:#{robot_name}") do
            app, message = capture_stdout do
              module_name = workflow.split('WF').first.capitalize
              robot_klass = Module.const_get(module_name).const_get(robot_name.split(/-/).collect { |w| w.capitalize }.join(''))
              robot = robot_klass.new
              robot_proc = lambda {
                Dir.chdir(@working_dir) do
                  loop { sleep(15*60) unless robot.start }
                end
              }
              new_app = self.new_application({:mode => :proc, :proc => robot_proc})
              new_app.start
              new_app
            end
          end
          
          if app.running?
            @logger.info "#{workflow}:#{robot_name} [#{app.pid.pid}] started."
            result = true
          else
            @logger.error "Unable to start #{workflow}:#{robot_name}"
          end
        else app.running?
          @logger.warn "Robot #{workflow}:#{robot_name} [#{app.pid.pid}] is already running"
        end
        return result
      end

      def stop(workflow, robot_name)
        apps = find_app(workflow, robot_name)
        result = false
        if apps.empty?
          @logger.info "Robot #{workflow}:#{robot_name} not found"
        else
          apps.each do |app|
            if app.running?
              @logger.info "Shutting down #{workflow}:#{robot_name} [#{app.pid.pid}]..."
              result, message = capture_stdout { app.stop }
              if app.running?
                @logger.error "Unable to stop #{workflow}:#{robot_name} [#{app.pid.pid}]."
              else
                @logger.info "#{workflow}:#{robot_name} [#{app.pid.pid}] shut down."
                result = true
              end
            else
              @logger.warn "Robot #{workflow}:#{robot_name} [#{app.pid.pid}] is not running but pidfile exists"
              app.zap!
            end
          end
        end
        result
      end
  
      def status(workflow, robot_name)
        apps = find_app(workflow, robot_name)
        apps.collect do |app|
          { :pid => app.pid.pid, :status => app.running? ? :running : :stopped }
        end
      end
  
      def status_message(workflow, robot_name)
        app_status = status(workflow, robot_name)
        if app_status.empty?
          ["Robot #{workflow}:#{robot_name} not found"]
        else
          app_status.collect do |s|
            case s[:status]
            when :running
              "Robot #{workflow}:#{robot_name} [#{s[:pid]}] is running"
            when :stopped
              "Robot #{workflow}:#{robot_name} [#{s[:pid]}] is not running but pidfile exists"
            end
          end
        end
      end
  
      private
      def with_app_name(name)
        old_name, @app_name = @app_name, name
        begin
          return yield
        ensure
          @app_name = old_name
        end
      end
      
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
  
      def find_app(workflow, robot_name)
        self.find_applications_by_app_name("#{workflow}:#{robot_name}")
      end
  
    end
  end
end