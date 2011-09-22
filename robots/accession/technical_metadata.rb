
module Accession

  class TechnicalMetadata < LyberCore::Robots::Robot

    def initialize(opts = {})
      super('accessionWF', 'technical-metadata', opts)
    end

  end

end


