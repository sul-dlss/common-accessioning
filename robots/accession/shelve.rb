module Accession

  class Shelve < LyberCore::Robots::Robot

    def initialize
      super('dor', 'accessionWF', 'shelve')
    end

    def process_item
      obj = Dor::Item.find(@druid)
      obj.shelve
    end

  end
end
