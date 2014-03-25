# Ensures the existence of a given datastream within
# a digital object, and loads it from the appropriate
# source if necessary.

module Accession

  class AbstractMetadata < LyberCore::Robots::Robot
    def self.params
      { :process_name => nil, :datastream => nil }
    end

    def initialize
      super('dor', 'accessionWF', self.class.params[:process_name])
    end

    def process_item
      obj = Dor::Item.find(@druid)
      obj.build_datastream(self.class.params[:datastream], self.class.params[:force] ? true : false, self.class.params[:require] ? true : false)
    end
  end
end