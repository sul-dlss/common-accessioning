
module Dissemination

  class Cleanup < LyberCore::Robots::Robot

    def initialize(opts = {})
      super('disseminationWF', 'cleanup', opts)
    end

    def process_item(work_item)
      Dor::CleanupService.cleanup work_item
    end

  end
end