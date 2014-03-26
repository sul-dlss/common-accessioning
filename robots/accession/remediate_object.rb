# Runs all registered dor-services migrations on the object

module Accession

  class RemediateObject < LyberCore::Robots::Robot

    def initialize
      super('dor', 'accessionWF', 'remediate-object')
    end

    def perform(druid)
      obj = Dor::Item.find(druid)
      obj.upgrade!
    end
  end
end
