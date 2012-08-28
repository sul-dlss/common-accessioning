require 'pony'
require 'stomp'
require 'rest-client'

module Accession
  
  class PublicXmlUpdater
    
    # For Initialization testing
    attr_reader :host
    attr_accessor :msg, :conn, :heart_beat_timeout
 
    def PublicXmlUpdater.start_daemon
      updater = Accession::PublicXmlUpdater.new
      updater.connect
      updater.run
    end
    
    def initialize
      LyberCore::Log.set_logfile(File.join(ROBOT_ROOT, "log", "republisher.log"))
      @host = URI.parse(Dor::Config.fedora.url).host
      @port = 61613
      @destination = "/topic/fedora.apim.update"
      @client_id = "public-xml-updater"
      @heart_beat_timeout = 899   # Send a heartbeat every 15 minutes of inactivity
    end

    def connect
      msg_broker_config = {
        :hosts => [{:login => 'public_xml_updater', :host => @host, :port => @port}],
        :initial_reconnect_delay => 1.0,
        :use_exponential_back_off => true,
        :back_off_multiplier => 1.05,
        :max_reconnect_delay => 3.0,
        :reliable => true,
        :connect_headers => {"client-id" => @client_id }
      }

      @conn = Stomp::Connection.new(msg_broker_config)
      @conn.subscribe(@destination,
                      "activemq.subscriptionName" => @client_id,
                      "selector" => "methodName IN ('modifyDatastreamByValue','modifyDatastreamByReference','addDatastream')",
                      :ack =>"client" )
    end
    
    def run
      LyberCore::Log.info("Waiting for #{@destination} messages")
      while true
        receive_messages
      end 
      @conn.join
    end

    def receive_messages
      raw_message = nil
      Timeout::timeout(@heart_beat_timeout) { raw_message = @conn.receive }
      if(raw_message.nil?)
        LyberCore::Log.warn("!!! Received nil message")
        return
      end
      @druid = nil
      @msg = Nokogiri::XML(raw_message.body)
      process_message
      @conn.ack raw_message.headers["message-id"]
      @msg = nil
    rescue Timeout::Error => te
      LyberCore::Log.info("Connection Idle, sending heartbeat...")
      begin
        @conn.begin('heartbeat')
        @conn.commit('heartbeat')
        LyberCore::Log.info("Heartbeat Sent")
      rescue Exception => he
        body = "Unable to send heartbeat to broker\n"
        body << "\n\nExeption:\n" << he.inspect << "\n" << he.backtrace.join("\n")
        send_alert("Re-publisher stopped: heartbeat failed", body)
        Lybercore::Log.fatal("Unable to send heartbeat")
        Lybercore::Log.fatal(body)
        raise he
      end
    rescue SystemExit => se
       LyberCore::Log.info("Exiting updater")
       raise se
    rescue Exception => e
      body = "Unable to re-publish metadata\n"
      body << "Message from DOR/FEDORA:\n" << @msg.to_xml unless @msg.nil?
      body << "\n\nExeption:\n" << e.inspect << "\n" << e.backtrace.join("\n")
      LyberCore::Log.fatal("!!!!!!!!!!!\n" << body << "!!!!!!!!!!!\n")
      if(@druid.nil?)
        LyberCore::Log.fatal("No druid. Sending alert")
        send_alert("Failed to republish metadata", body)
      else
        Dor::WorkflowService.update_workflow_error_status('dor', @druid, 'disseminationWF', 'publish', e.inspect, e.backtrace.join("\n"))
      end
    end
    
    def send_alert(subject, body)
      Pony.mail(:to => "wmene@stanford.edu, lmcrae@stanford.edu",
                :from => "public-xml-updater@stanford.edu",
                :subject => "[#{ENV['ROBOT_ENVIRONMENT']}] #{subject}",
                :body => body,
                :via => :smtp,
                :via_options => {
                   :address        => 'smtp.stanford.edu',
                   :port           => '25',
                   :enable_starttls_auto => true,
                   :authentication => :plain, # :plain, :login, :cram_md5, no auth by default
                   :domain         => "localhost.localdomain" # the HELO domain provided by the client to the server
                 }
       )
    end
        
    # Republish the object only if the message dealt with the correct datastream and the item has already been released
    def process_message
      start_time = Time.new
      return unless correct_datastream?
      
      @druid = @msg.at_xpath("//xmlns:entry/xmlns:category[@scheme='fedora-types:pid']")['term']
      return unless ['released','published'].any? { |lifecycle| Dor::WorkflowService.get_lifecycle('dor', @druid, lifecycle) }

      LyberCore::Log.info("Updating metadata for: #{@druid}")
      
      item = Dor::Item.load_instance(@druid)
      item.publish_metadata
      elapsed = Time.new - start_time
      Dor::WorkflowService.update_workflow_status('dor', @druid, 'disseminationWF', 'publish', 'completed', elapsed, 'published')
    end
    
    def correct_datastream?
      if(@msg.at_xpath("//xmlns:entry/xmlns:category[@scheme='fedora-types:dsID' and " <<
                      "(@term = 'identityMetadata' or @term = 'contentMetadata' or @term = 'rightsMetadata' or @term = 'descMetadata' or @term = 'RELS-EXT')]"))
        return true
      else
        return false
      end
    end
        
  end
end

