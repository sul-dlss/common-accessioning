# Clears the way for the standalone publishing robot to publish
# the object's metadata to the Digital Stacks' document cache

module Accession

  class Publish < LyberCore::Robots::Robot

    def initialize
      super('dor', 'accessionWF', 'shelve')
    end

    def perform(druid)
      obj = Dor::Item.find(druid)
      obj.publish_metadata
    end
  end
end