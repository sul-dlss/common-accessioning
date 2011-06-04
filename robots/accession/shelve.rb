#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../boot')


module Accession
  
  class Shelve < LyberCore::Robots::Robot

    def process_item(work_item)

    end
    
  end

end

if __FILE__ == $0
  r = Accession::Shelve.new('accessionWF', 'shelve')
  r.start
end

