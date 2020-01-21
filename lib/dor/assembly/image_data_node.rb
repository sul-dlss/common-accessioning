# frozen_string_literal: true

module Dor
  module Assembly
    # Represents an XML node which is a child of the file node in contentMetadata.xml
    class ImageDataNode
      NODE_NAME = 'imageData'

      def self.build(exif_data)
        w = exif_data.image_width
        h = exif_data.image_height
        %(<#{NODE_NAME} width="#{w}" height="#{h}"/>)
      end
    end
  end
end
