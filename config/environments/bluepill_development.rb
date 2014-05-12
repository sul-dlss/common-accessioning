WORKDIR=File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
robot_environment = ENV['ROBOT_ENVIRONMENT'] || 'development'
workflows = File.expand_path(File.join(WORKDIR, 'config', 'environments', "workflows_#{robot_environment}.rb"))
puts "Loading #{workflows}"
require workflows

Bluepill.application 'common-accessioning',
  :log_file => "#{WORKDIR}/log/bluepill.log" do |app|
  app.working_dir = WORKDIR
  WORKFLOW_STEPS.each_index do |i|
    # extract fully qualified WF properties
    qualified_wf = WORKFLOW_STEPS[i]
    n = qualified_wf.split(/:/).size
    raise ArgumentError unless n == 3 or n == 4
    wf = qualified_wf.split(/:/)[0..2].join('_')
    
    # prefix process name with index number to prevent
    # duplicate process names if wf is run multiple times
    app.process("#{i+1}:#{wf}") do |process|
      puts "Creating robot #{process.name}"

      # queue order is *VERY* important
      #
      # see RobotMaster::Queue#queue_name for naming convention
      #
      queues = []
      # check to see whether wf already includes priority
      if n == 4
        queues << qualified_wf.split(/:/).join('_')
      else
        # otherwise listen on all queues
        %w{critical high default low}.each do |p|
          queues << [wf, p].join('_')
        end
      end
      queues = queues.join(',')

      # use environment for these resque variables
      process.environment = {
        'QUEUES' => "#{queues}",
        'VERBOSE' => 'yes',
        'ROBOT_ENVIRONMENT' => robot_environment
      }

      # process configuration
      process.group = robot_environment
      process.stdout = process.stderr = "#{WORKDIR}/log/#{wf}.log"

      # spawn worker processes
      process.start_command = "rake environment resque:work"
      
      # we use bluepill to daemonize the resque workers rather than using
      # resque's BACKGROUND flag
      process.daemonize = true
      
      # bluepill manages pid files
      # process.pid_file = "#{WORKDIR}/run/#{wf}.pid"

      # graceful stops
      process.stop_grace_time = 360.seconds # must be greater than stop_signals total
      process.stop_signals = [
        :quit, 300.seconds, # waits for jobs, then exits gracefully
        :term, 10.seconds, # kills jobs and exits
        :kill              # no mercy
      ]

      # process monitoring

      # backoff if process is flapping between states
      # process.checks :flapping,
      #                :times => 2, :within => 30.seconds,
      #                :retry_in => 7.seconds

      # restart if process runs for longer than 15 mins of CPU time
      # process.checks :running_time,
      #                :every => 5.minutes, :below => 15.minutes

      # restart if CPU usage > 75% for 3 times, check every 10 seconds
      # process.checks :cpu_usage,
      #                :every => 10.seconds,
      #                :below => 75, :times => 3,
      #                :include_children => true
      #
      # restart the process or any of its children
      # if MEM usage > 100MB for 3 times, check every 10 seconds
      # process.checks :mem_usage,
      #                :every => 10.seconds,
      #                :below => 100.megabytes, :times => 3,
      #                :include_children => true

      # NOTE: there is an implicit process.keepalive
    end
  end
end
