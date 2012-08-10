# Initialize contentMetadata

module Accession
  
  class DescriptiveMetadata < AbstractMetadata
    def self.params
      { :process_name => 'descriptive-metadata', :datastream => 'descMetadata' }
    end
     # Modified version of processable.build_datastream that throws an exception if there is no content to put in the datastream
      def build_datastream(datastream, force = false)
        updated=false
        ds = datastreams[datastream]
        druid = DruidTools::Druid.new(self.pid, Dor::Config.stacks.local_workspace_root)
        filename = druid.find_metadata("#{datastream}.xml")
        if not filename.nil?
          content = File.read(filename)
          ds.content = content
          if(not content.nil)
            ds.ng_xml = Nokogiri::XML(content) if ds.respond_to?(:ng_xml)
            ds.save unless ds.digital_object.new?
          end
          #if the file doesnt exist and either force==true or the datastream is empty
        elsif force or empty_datastream?(ds)
          proc = "build_#{datastream}_datastream".to_sym
          #if the class this has been included in has a proc method
          if respond_to? proc
            content = self.send(proc, ds)
            if(not content.nil)
              updated=true
              ds.save unless ds.digital_object.new?
            end
          end
        end
        if not updated
          raise("No descriptive metadata found for "+ druid)
        end
        return ds
      end
  end
end