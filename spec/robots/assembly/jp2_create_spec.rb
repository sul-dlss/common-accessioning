# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Assembly::Jp2Create do
  let(:robot) { Robots::DorRepo::Assembly::Jp2Create.new(druid: druid) }

  def get_filenames(item)
    item.file_nodes.map { |fn| item.path_to_content_file fn['id'] }
  end

  def count_file_types(files, extension)
    files.select { |file| File.extname(file) == extension }.size
  end

  describe '#perform' do
    before do
      setup_assembly_item(druid, type)
    end

    subject(:perform) { robot.perform(@assembly_item) }
    let(:druid) { 'aa222cc3333' }

    context 'for an item' do
      let(:type) { :item }

      it 'creates jp2 for type=item' do
        expect(@assembly_item).to receive(:item?)
        expect(@assembly_item).to receive(:load_content_metadata)
        expect(robot).to receive(:create_jp2s).with(@assembly_item)
        perform
      end
    end

    context 'for a set' do
      let(:type) { :set }

      it 'does not create jp2 for type=set' do
        expect(@assembly_item).to receive(:item?)
        expect(@assembly_item).not_to receive(:load_content_metadata)
        expect(robot).not_to receive(:create_jp2s).with(@assembly_item)
        perform
      end
    end
  end

  describe '#create_jp2s' do
    before do
      clone_test_input TMP_ROOT_DIR
      # Ensure the files we modifiy are in tmp/
      allow(Dor::Config.assembly).to receive(:root_dir).and_return(TMP_ROOT_DIR)
    end

    let(:item) do
      Dor::Assembly::Item.new(druid: druid)
    end

    context 'when resource type is not specified' do
      let(:druid) { 'aa111bb2222' }
      before do
        allow_any_instance_of(Assembly::ObjectFile).to receive(:jp2able?).and_return(true)
        allow_any_instance_of(Assembly::Image).to receive(:create_jp2).with(overwrite: false, tmp_folder: '/tmp').and_return(instance_double(Assembly::Image, path: 'spec/out/image111.jp2'))
      end

      let(:jp2s) { tifs.map { |t| t.sub(/\.tif$/, '.jp2') } }
      let(:tifs) { item.file_nodes.map { |fn| item.path_to_content_file fn['id'] } }

      it 'does not create any jp2 files' do
        item.load_content_metadata

        # Only tifs should exist.
        expect(item.file_nodes.size).to eq(3)
        expect(tifs.all?  { |t| File.file? t }).to eq(true)
        expect(jp2s.none? { |j| File.file? j }).to eq(true)

        # We now have jp2s since all resource types = image
        robot.send(:create_jp2s, item)
        files = get_filenames(item)
        expect(item.file_nodes.size).to eq(6)
        expect(count_file_types(files, '.tif')).to eq(3)
        expect(count_file_types(files, '.jp2')).to eq(3)
      end
    end

    context 'with mixed resource types' do
      let(:druid) { 'ff222cc3333' }
      before do
        allow_any_instance_of(Assembly::ObjectFile).to receive(:jp2able?).and_return(true)
      end

      it 'creates jp2 files only for resource type image or page' do
        item.load_content_metadata
        bef_files = get_filenames(item)

        # there should be 10 file nodes in total
        expect(item.file_nodes.size).to eq(10)
        expect(count_file_types(bef_files, '.tif')).to eq(5)
        expect(count_file_types(bef_files, '.jp2')).to eq(1)

        expect(robot).to receive(:create_jp2).twice
        robot.send(:create_jp2s, item)
      end
    end

    context 'for resource type image or page in new location' do
      let(:druid) { 'gg111bb2222' }

      before do
        item.cm_file_name = item.path_to_metadata_file(Dor::Config.assembly.cm_file_name)
        allow_any_instance_of(Assembly::ObjectFile).to receive(:jp2able?).and_return(true)

        # These files needs to create
        d1 = instance_double(Assembly::Image, path: 'spec/out/image111.jp2')
        s1 = Assembly::Image.new('tmp/test_input/gg/111/bb/2222/gg111bb2222/content/image111.tif')
        allow(s1).to receive(:create_jp2).and_return(d1)

        # These files needs to create
        d2 = instance_double(Assembly::Image, path: 'spec/out/image112.jp2')
        s2 = Assembly::Image.new('tmp/test_input/gg/111/bb/2222/gg111bb2222/content/image112.tif')
        allow(s2).to receive(:create_jp2).and_return(d2)

        # These files needs to create
        d3 = instance_double(Assembly::Image, path: 'spec/out/image113.jp2')
        s3 = Assembly::Image.new('tmp/test_input/gg/111/bb/2222/gg111bb2222/content/image113.tif')
        allow(s3).to receive(:create_jp2).and_return(d3)

        allow(Assembly::Image).to receive(:new).and_return(s1, s2, s3)
      end

      it 'creates jp2 files only for the resource type image or page in new location' do
        item.load_content_metadata
        bef_files = get_filenames(item)

        # there should be 3 file nodes in total
        expect(item.file_nodes.size).to eq(3)
        expect(count_file_types(bef_files, '.tif')).to eq(3)
        expect(count_file_types(bef_files, '.jp2')).to eq(0)

        robot.send(:create_jp2s, item)

        # we now have three jps
        expect(item.file_nodes.size).to eq(6)
        aft_files = get_filenames(item)
        expect(count_file_types(aft_files, '.tif')).to eq(3)
        expect(count_file_types(aft_files, '.jp2')).to eq(3)

        # Read the XML file and check the file names.
        xml = Nokogiri::XML File.read(item.cm_file_name)
        file_nodes = xml.xpath '//resource/file'
        expect(file_nodes.map { |fn| fn['id'] }.sort).to eq(['image111.jp2', 'image111.tif', 'image112.jp2', 'image112.tif', 'sub/image113.jp2', 'sub/image113.tif'])
      end
    end

    context 'when some files exist' do
      let(:druid) { 'ff222cc3333' }
      let(:copy_jp2) { File.join TMP_ROOT_DIR, 'ff/222/cc/3333', 'image115.jp2' }
      before do
        # copy an existing jp2
        source_jp2 = File.join TMP_ROOT_DIR, 'ff/222/cc/3333', 'image111.jp2'
        system "cp #{source_jp2} #{copy_jp2}"
      end

      after do
        # cleanup copied jp2
        system "rm #{copy_jp2}"
      end

      context 'and overwrite is false' do
        before do
          Dor::Config.assembly.overwrite_jp2 = false

          allow_any_instance_of(Assembly::ObjectFile).to receive(:jp2able?).and_return(true)
          out1 = 'tmp/test_input/ff/222/cc/3333/image114.jp2'
          d1 = instance_double(Assembly::Image, path: out1)
          s1 = instance_double(Assembly::Image, 'source 1', dpg_jp2_filename: out1, jp2_filename: out1, path: 'tmp/test_input/ff/222/cc/3333/image114.tif', create_jp2: d1)
          s2 = instance_double(Assembly::Image, 'source 2', dpg_jp2_filename: copy_jp2, jp2_filename: copy_jp2, path: 'tmp/test_input/ff/222/cc/3333/image115.tif')
          allow(Assembly::Image).to receive(:new).and_return(s1, s2)
        end

        it 'does not overwrite existing jp2s but should not fail either' do
          item.load_content_metadata
          bef_files = get_filenames(item)

          # there should be 10 file nodes in total
          expect(item.file_nodes.size).to eq(10)
          expect(count_file_types(bef_files, '.tif')).to eq(5)
          expect(count_file_types(bef_files, '.jp2')).to eq(1)

          expect(File.exist?(copy_jp2)).to eq(true)

          robot.send(:create_jp2s, item)

          # we now have only one extra jp2, only for the resource nodes that had type=image or page specified, since one was not created because it was already there
          expect(item.file_nodes.size).to eq(11)
          aft_files = get_filenames(item)
          expect(count_file_types(aft_files, '.tif')).to eq(5)
          expect(count_file_types(aft_files, '.jp2')).to eq(2)
        end
      end

      context 'and overwrite is true' do
        before do
          Dor::Config.assembly.overwrite_jp2 = true

          allow_any_instance_of(Assembly::ObjectFile).to receive(:jp2able?).and_return(true)
          out1 = 'tmp/test_input/ff/222/cc/3333/image114.jp2'
          d1 = instance_double(Assembly::Image, path: out1)
          s1 = instance_double(Assembly::Image, 'source 1', dpg_jp2_filename: out1, jp2_filename: out1, path: 'tmp/test_input/ff/222/cc/3333/image114.tif', create_jp2: d1)
          s2 = instance_double(Assembly::Image, 'source 2', dpg_jp2_filename: copy_jp2, jp2_filename: copy_jp2, path: 'tmp/test_input/ff/222/cc/3333/image115.tif')
          allow(Assembly::Image).to receive(:new).and_return(s1, s2)
        end

        it 'overwrites existing jp2s but should not fail either' do
          item.load_content_metadata
          bef_files = get_filenames(item)

          # there should be 10 file nodes in total
          expect(item.file_nodes.size).to eq(10)
          expect(count_file_types(bef_files, '.tif')).to eq(5)
          expect(count_file_types(bef_files, '.jp2')).to eq(1)

          expect(File.exist?(copy_jp2)).to eq(true)

          robot.send(:create_jp2s, item)

          expect(item.file_nodes.size).to eq(11)
          aft_files = get_filenames(item)
          expect(count_file_types(aft_files, '.tif')).to eq(5)
          expect(count_file_types(aft_files, '.jp2')).to eq(2)
        end
      end
    end

    context 'when there is a DPG style jp2 already there' do
      let(:druid) { 'hh222cc3333' }

      # This file does not need to create, unless overwrite is on.
      let(:source1) do
        Assembly::Image.new('tmp/test_input/hh/222/cc/3333/hh222cc3333_00_001.tif')
      end

      # This file has an existing dpg format jp2
      let(:source2) do
        Assembly::Image.new('tmp/test_input/hh/222/cc/3333/hh222cc3333_05_001.jp2')
      end

      before do
        Dor::Config.assembly.overwrite_jp2 = false

        allow_any_instance_of(Assembly::ObjectFile).to receive(:jp2able?).and_return(true)

        # These files needs to create
        d3 = instance_double(Assembly::Image, path: 'tmp/test_input/hh/222/cc/3333/hh222cc3333_00_002.jp2')
        s3 = Assembly::Image.new('tmp/test_input/hh/222/cc/3333/hh222cc3333_00_002.tif')
        allow(s3).to receive(:create_jp2).and_return(d3)

        d4 = instance_double(Assembly::Image, path: 'tmp/test_input/hh/222/cc/3333/hh222cc3333_00_003.jp2')
        s4 = Assembly::Image.new('tmp/test_input/hh/222/cc/3333/hh222cc3333_00_003.tif')
        allow(s4).to receive(:create_jp2).and_return(d4)

        d5 = instance_double(Assembly::Image, path: 'tmp/test_input/hh/222/cc/3333/hh222cc3333_00_004.jp2')
        s5 = Assembly::Image.new('tmp/test_input/hh/222/cc/3333/hh222cc3333_00_004.tif')
        allow(s5).to receive(:create_jp2).and_return(d5)

        d6 = instance_double(Assembly::Image, path: 'tmp/test_input/hh/222/cc/3333/hh222cc3333_00_005.jp2')
        s6 = Assembly::Image.new('tmp/test_input/hh/222/cc/3333/hh222cc3333_00_005.tif')
        allow(s6).to receive(:create_jp2).and_return(d6)

        allow(Assembly::Image).to receive(:new).and_return(source1, source2, s3, s4, s5, s6)
      end

      context 'and overwrite is false' do
        before do
          Dor::Config.assembly.overwrite_dpg_jp2 = false
        end

        it 'does not overwrite existing jp2s' do
          item.load_content_metadata
          bef_files = get_filenames(item)

          # there should be 6 file nodes in total to start
          expect(item.file_nodes.size).to eq(6)
          expect(count_file_types(bef_files, '.tif')).to eq(5)
          expect(count_file_types(bef_files, '.jp2')).to eq(1)

          robot.send(:create_jp2s, item)

          # we now have three extra jp2, one for each tif that didn't have a matching dpg style jp2
          # even if the jp2 does not exist in the original content metadata, if a matching one is found, a derivative won't be created
          expect(item.file_nodes.size).to eq(9) # there are 9 total nodes, 4 jp2 and 5 tif
          aft_files = get_filenames(item)
          expect(count_file_types(aft_files, '.tif')).to eq(5)
          expect(count_file_types(aft_files, '.jp2')).to eq(4)
        end
      end

      context 'and overwrite is true' do
        let(:out2) { 'tmp/test_input/hh/222/cc/3333/hh222cc3333_00_001.jp2' }

        before do
          Dor::Config.assembly.overwrite_dpg_jp2 = true
          allow(source1).to receive(:create_jp2).and_return(instance_double(Assembly::Image, path: out2))
          allow(source2).to receive(:create_jp2).and_return(instance_double(Assembly::Image, path: out2))
        end

        it 'overwrites existing jp2s' do
          item.load_content_metadata
          bef_files = get_filenames(item)

          # there should be 6 file nodes in total to start
          expect(item.file_nodes.size).to eq(6)
          expect(count_file_types(bef_files, '.tif')).to eq(5)
          expect(count_file_types(bef_files, '.jp2')).to eq(1)

          robot.send(:create_jp2s, item)

          expect(item.file_nodes.size).to eq(11)
          aft_files = get_filenames(item)
          expect(count_file_types(aft_files, '.tif')).to eq(5)
          expect(count_file_types(aft_files, '.jp2')).to eq(6)
        end
      end
    end
  end

  describe '#add_jp2_file_node' do
    let(:druid) { 'aa111bb2222' }
    let(:exp_xml) do
      <<-XML.gsub(/^ {8}/, '')
        <?xml version="1.0"?>
        <contentMetadata>
          <resource>
            <file id="foo.tif"/>
          </resource>
        </contentMetadata>
      XML
    end

    let(:resource_node) do
      content_metadata.xpath('//resource').first
    end

    let(:content_metadata) do
      Nokogiri.XML(xml) { |conf| conf.default_xml.noblanks }
    end

    let(:xml) { '<contentMetadata><resource></resource></contentMetadata>' }

    it 'adds a <file> node to XML if the resource type is not specified' do
      robot.send :add_jp2_file_node, resource_node, 'foo.tif'
      expect(content_metadata).to be_equivalent_to exp_xml
    end
  end
end
