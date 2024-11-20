# frozen_string_literal: true

module Dor
  module TextExtraction
    # Update Cocina structural metadata with files that have been
    # added to a workspace directory.
    #
    # This is the base class, with logic specific to OCR or speech to text in sub classes.
    #
    # The logic for updating the Cocina is:
    #
    # 1. Look at each file in the workspace's content directory.
    # 2. If the file will overwrite an existing file in Cocina ensure that
    #    the file to be overwritten was generated by SDR and has not been
    #    corrected.
    # 3. If the file already exists in the Cocina update it by first deleting
    #    from the Cocina and then adding it again.
    # 4. If the file does not exist in the Cocina already look find a resource
    #    that contains the same filename "stem" and add the file there. e.g.
    #    "abc123.xml" would be added to the same resource that contains
    #    "abc123.tiff".
    #
    # rubocop:disable Metrics/ClassLength
    class CocinaUpdater
      attr_reader :dro, :logger

      delegate :externalIdentifier, :version, :structural, to: :dro

      # @param dro [Cocina::Models::Dro] the object metadata to update in place
      def self.update(dro:, logger: nil)
        new(dro:, logger:).update
      end

      def initialize(dro:, logger: nil)
        @dro = dro
        @logger = logger || Logger.new($stdout)
      end

      def update
        update_cocina

        dro
      end

      private

      # update the cocina with new files from the workspace
      def update_cocina
        # TODO: this assumes non-hierarchical files
        content_dir.children.sort.each do |file|
          logger.info("examining #{file}")
          next unless include_file?(file)
          next unless can_overwrite?(file)

          if file_in_cocina?(file)
            update_file(file)
          else
            add_file(file)
          end
        end
      end

      def update_file(path)
        logger.info("updating #{path} in cocina")
        resource = find_resource(path)

        delete_file_from_resource(path, resource)
        add_file_to_resource(path, resource)
      end

      def add_file(path)
        logger.info("adding #{path} to cocina")
        resource = find_resource_with_stem(path)

        # NOTE: we want to add item level pdf and txt files as new resources.
        if resource && !path.basename.to_s.match(/^#{bare_druid}\.(pdf|txt)$/)
          add_file_to_resource(path, resource)
        else
          add_file_to_new_resource(path)
        end
      end

      def add_file_to_resource(path, resource)
        resource.structural.contains.push(file(path))
      end

      def delete_file_from_resource(path, resource)
        resource.structural.contains.delete_if { |file| file.filename == path.basename.to_s }
      end

      def add_file_to_new_resource(path)
        structural.contains.push(
          Cocina::Models::FileSet.new(
            externalIdentifier: resource_identifier,
            type: resource_type(path),
            version:,
            label: resource_label(path),
            structural: { contains: [file(path)] }
          )
        )
      end

      def file_in_cocina?(path)
        find_cocina_file(path) ? true : false
      end

      def find_cocina_file(path)
        dro_files.find { |file| file.filename == path.basename.to_s }
      end

      def dro_files
        # TODO: replace with Cocina::Models::Utils.files when that's available
        structural.contains.flat_map do |fileset|
          fileset.structural.contains
        end
      end

      def find_workspace_file(filename)
        path = content_dir + filename
        path.exist? ? path : nil
      end

      # you can override this in a subclass to only include certain files in the workspace
      def include_file?(_file)
        !file.basename.to_s.start_with?('.')
      end

      # prevent non SDR generated OCR and corrected OCR from being overwritten
      def can_overwrite?(path)
        file = find_cocina_file(path)
        if !file || (file.sdrGeneratedText == true && file.correctedForAccessibility == false)
          true
        else
          # remove it from the workspace so that accessionWF doesn't get confused
          logger.info("preventing update of #{file.filename} sdrGeneratedText=#{file.sdrGeneratedText} correctedForAccessibility=#{file.correctedForAccessibility}")
          path.delete
          false
        end
      end

      # Find a Cocina resource that contains the given filename.
      # @param path {String} - the path to look for
      # @return {FileSet, nil} - the resource or nil if it is not found
      def find_resource(path)
        structural.contains.detect do |resource|
          resource.structural.contains.detect do |file|
            file.filename == path.basename.to_s
          end
        end
      end

      # Find a Cocina resource for the given path by looking for a resource that has a matching filename "stem".
      # @param path {String} - the path to look for
      # @return {FileSet, nil} - the resource or nil if it is not found
      def find_resource_with_stem(path)
        file_stem = stem(path)
        structural.contains.detect do |resource|
          resource.structural.contains.detect do |file|
            stem(file.filename) == file_stem
          end
        end
      end

      def file(path)
        object_file = ::Assembly::ObjectFile.new(path)
        Cocina::Models::File.new(cocina_file_attributes(object_file))
      end

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def cocina_file_attributes(object_file)
        {}.tap do |file_attributes|
          file_attributes[:externalIdentifier] = file_identifier
          file_attributes[:label] = object_file.filename
          file_attributes[:use] = use(object_file)
          file_attributes[:sdrGeneratedText] = true
          file_attributes[:correctedForAccessibility] = false
          file_attributes[:type] = Cocina::Models::ObjectType.file
          file_attributes[:filename] = object_file.filename
          file_attributes[:version] = version
          file_attributes[:languageTag] = language(object_file.path) if language(object_file.path)
          file_attributes[:hasMimeType] = object_file.mimetype
          file_attributes[:hasMessageDigests] = message_digests(object_file)
          file_attributes[:size] = object_file.filesize
          file_attributes[:access] = access
          file_attributes[:administrative] = administrative
        end
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      # you can override this in a subclass to set the languageTag attribute if needed
      def language(_path)
        nil
      end

      def access
        {
          view: 'world',
          download: 'world'
        }
      end

      # set the use/role attribute
      def use(_object_file)
        raise 'Override this in a subclass'
      end

      def administrative
        {
          publish: true,
          sdrPreserve: true,
          shelve: true
        }
      end

      def message_digests(object_file)
        [
          {
            type: 'md5',
            digest: object_file.md5
          },
          {
            type: 'sha1',
            digest: object_file.sha1
          }
        ]
      end

      def resource_label(_path)
        raise 'Override this in a subclass'
      end

      def resource_type(path)
        if path.extname == '.pdf' && document?
          Cocina::Models::FileSetType.document
        else
          Cocina::Models::FileSetType.object
        end
      end

      def stem(path)
        File.basename(path, '.*').to_s
      end

      def file_identifier
        "https://cocina.sul.stanford.edu/file/#{SecureRandom.uuid}"
      end

      def resource_identifier
        "#{bare_druid}_#{structural.contains.length + 1}"
      end

      def bare_druid
        druid_tools.id
      end

      def content_dir
        Pathname.new(druid_tools.content_dir)
      end

      def druid_tools
        @druid_tools ||= DruidTools::Druid.new(externalIdentifier, Settings.sdr.local_workspace_root)
      end

      def document?
        dro.type == Cocina::Models::ObjectType.document
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
