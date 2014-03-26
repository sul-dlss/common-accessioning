
module Dissemination

  class Cleanup
    include LyberCore::Robot

    def initialize
      super('dor', 'disseminationWF', 'cleanup')
    end

    def perform(druid)
      Dor::CleanupService.cleanup_by_druid druid
    end

  end
end