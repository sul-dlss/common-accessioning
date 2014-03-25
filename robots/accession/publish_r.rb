
# self.perform is simple
# the #perform instance method handles
module Accession

  class PublishR
    #@queue = 'accessionWF_content_metadata'
    #Resque.enqueue_to(q.to_sym, klass, druid)
    def self.perform(druid)
      bot = PublishR.new(druid)
      bot.perform
    end

    def initialize(druid)
      @druid = druid
    end

    def perform
      begin
        LyberCore::Log.set_logfile(File.join(ROBOT_ROOT, 'log', 'publish-r.log'))
        LyberCore::Log.info "#{self.class.name} processing #{@druid}"
        self.process_item
        Dor::WorkflowService.update_workflow_status 'dor', @druid, 'accessionWF', 'content-metadata', 'completed'

      rescue => e
        LyberCore::Log.error e.message + "\n" + e.backtrace.join("\n")
        Dor::WorkflowService.update_workflow_error_status 'dor', @druid, 'accessionWF', 'content-metadata', e.message + "\n" + e.backtrace.join("\n")
        raise e  # or just swallow the error
      end
    end

    # ^^^^^^^^^^^^^^
    # Above goes into new lyber-core
    # Below is individual robot code

    def process_item
      obj = Dor::Item.find(@druid)
      obj.publish
    end
  end
end
