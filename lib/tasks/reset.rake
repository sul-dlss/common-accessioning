require 'rubygems'
require 'lyber_core'

namespace :reset do
  
  namespace :googleScannedBookWF do
  
  LyberCore::Log.set_level(0)
  
    desc "Delete all of the googleScannedBookWF objects from dor-dev"
    task :dev do
      require File.expand_path(File.dirname(__FILE__) + "/../../config/environments/lyberservices-dev")
      logfile = "#{ROBOT_ROOT}/log/reset_googleScannedBookWF_dev.log"
      LyberCore::Log.set_logfile(logfile)
      dfo = LyberCore::Destroyer.new("dor","googleScannedBookWF", "register-object")
      dfo.delete_druids
    end
    
    desc "Delete all of the googleScannedBookWF objects from dor-test"
    task :test do
      require File.expand_path(File.dirname(__FILE__) + "/../../config/environments/lyberservices-test")
      logfile = "#{ROBOT_ROOT}/log/reset_googleScannedBookWF_test.log"
      LyberCore::Log.set_logfile(logfile)
      dfo = LyberCore::Destroyer.new("dor","googleScannedBookWF", "register-object")
      dfo.delete_druids
    end

  end
  
end