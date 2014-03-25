
module Accession

  class ContentMetadataR
    #@queue = 'accessionWF_content_metadata'
    #Resque.enqueue_to(q.to_sym, klass, druid)
    def self.perform(druid)
      begin
        LyberCore::Log.set_logfile(File.join(ROBOT_ROOT, 'log', 'content-metadata-r.log'))
        bot = ContentMetadataR.new(druid)
        LyberCore::Log.info "#{self.name} processing #{druid}"
        bot.perform
        Dor::WorkflowService.update_workflow_status 'dor', druid, 'accessionWF', 'content-metadata', 'completed'
      rescue => e
        LyberCore::Log.error e.message + "\n" + e.backtrace.join("\n")
        Dor::WorkflowService.update_workflow_error_status 'dor', druid, 'accessionWF', 'content-metadata',e.message + "\n" + e.backtrace.join("\n")
        raise e
      end
    end

    def initialize(druid)
      @druid = druid
    end

    def perform
      obj = Dor::Item.find(@druid)
      obj.build_datastream('contentMetadata', true, true)
    end
  end
end
