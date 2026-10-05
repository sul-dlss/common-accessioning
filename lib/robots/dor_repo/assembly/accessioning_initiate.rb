# frozen_string_literal: true

module Robots
  module DorRepo
    module Assembly
      # This creates a symlink in /dor/workspace to the files in /dor/assembly
      # (i.e. /dor//workspace/xw/754/sd/7436/xw754sd7436 -> /dor/assembly/xw/754/sd/7436/xw754sd7436)
      # and then triggers the accessioningWF.
      # The symlink is not created for content in staging, since accessionWF's stage step copies it to the workspace.
      class AccessioningInitiate < Robots::DorRepo::Assembly::Base
        def initialize
          super('assemblyWF', 'accessioning-initiate')
        end

        def perform_work
          logger.info("Initiate accessioning for #{druid}")
          initialize_workspace if assembly_item.item?
          close_version
          true
        end

        private

        def initialize_workspace
          path = assembly_item.path_finder.path_to_object
          return if staged?(path)

          object_client.workspace.create(source: path)
        end

        def staged?(path)
          path.start_with?("#{Settings.sdr.staging_root}/")
        end

        def close_version
          object_client.version.close(lane_id:)
        end
      end
    end
  end
end
