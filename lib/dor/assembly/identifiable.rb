# frozen_string_literal: true

module Dor::Assembly
  module Identifiable
    def object_type
      obj_type = object.identityMetadata.objectType
      (obj_type.nil? ? 'unknown' : obj_type.first)
    end

    def item?
      object_type.downcase.strip == 'item'
    end
  end
end
