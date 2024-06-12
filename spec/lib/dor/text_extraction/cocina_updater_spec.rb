# frozen_string_literal: true

require 'spec_helper'

describe Dor::TextExtraction::CocinaUpdater do
  # NOTE: this context makes workspace_dir, workspace_content_dir and workspace_metadata_dir available
  include_context 'with workspace dir'

  let(:druid) { 'druid:bb222cc3333' }
  let(:bare_druid) { 'bb222cc3333' }
  let(:dro) do
    build(:dro, id: druid).new(
      type: item_type,
      structural: {
        contains: original_resources
      }
    )
  end
  # DruidTools needs to return the workspace_dir set up by "with workspace dir" context
  let(:druid_tools) do
    instance_double(DruidTools::Druid, id: bare_druid, content_dir: workspace_content_dir)
  end

  before { allow(DruidTools::Druid).to receive(:new).and_return(druid_tools) }

  context 'when there is a single image' do
    let(:item_type) { Cocina::Models::ObjectType.image }
    let(:resource_type) { Cocina::Models::FileSetType.image }

    let(:original_resources) do
      [
        {
          externalIdentifier: "#{bare_druid}_1",
          label: 'Fileset 1',
          type: resource_type,
          version: 1,
          structural: {
            contains: [
              {
                externalIdentifier: "#{bare_druid}_1",
                label: 'Page 1',
                type: Cocina::Models::ObjectType.file,
                version: 1,
                filename: 'image1.tif',
                hasMimeType: 'image/tiff'
              }
            ]
          }
        }
      ]
    end

    let(:resource1_files) { dro.structural.contains[0].structural.contains }

    before do
      create_txt_file('image1.txt')
      create_xml_file('image1.xml')
      create_pdf_file("#{bare_druid}.pdf")
      create_txt_file("#{bare_druid}.txt")

      described_class.update(dro:)
    end

    it 'first resource has expected number of files' do
      expect(resource1_files.length).to be 3
    end

    it 'first resource still has first file set correctly' do
      file = resource1_files[0]
      expect(file.label).to eq 'Page 1'
      expect(file.filename).to eq 'image1.tif'
      expect(file.sdrGeneratedText).to be false
      expect(file.correctedForAccessibility).to be false
    end

    # rubocop:disable RSpec/ExampleLength
    it 'first resource has text file set correctly' do
      file = resource1_files[1]
      expect(file.label).to eq 'image1.txt'
      expect(file.filename).to eq 'image1.txt'
      expect(file.use).to eq 'transcription'
      expect(file.sdrGeneratedText).to be true
      expect(file.correctedForAccessibility).to be false
      expect(file.access.view).to be 'world'
      expect(file.access.download).to be 'world'
      expect(file.administrative.publish).to be true
      expect(file.administrative.sdrPreserve).to be true
      expect(file.administrative.shelve).to be true
      expect(file.hasMimeType).to eq 'text/plain'
      expect(file.hasMessageDigests[0].type).to eq 'md5'
      expect(file.hasMessageDigests[0].digest).to eq '6d98df7e7b6faa698f3458714e2d0eee'
      expect(file.hasMessageDigests[1].type).to eq 'sha1'
      expect(file.hasMessageDigests[1].digest).to eq '8dbc9709e00f49523566107de23e4e603aab5f70'
    end

    it 'first resource has abbyy xml ocr file set correctly' do
      file = resource1_files[2]
      expect(file.label).to eq 'image1.xml'
      expect(file.filename).to eq 'image1.xml'
      expect(file.use).to eq 'transcription'
      expect(file.sdrGeneratedText).to be true
      expect(file.correctedForAccessibility).to be false
      expect(file.access.view).to be 'world'
      expect(file.access.download).to be 'world'
      expect(file.administrative.publish).to be true
      expect(file.administrative.sdrPreserve).to be true
      expect(file.administrative.shelve).to be true
      expect(file.hasMimeType).to eq 'application/xml'
    end
    # rubocop:enable RSpec/ExampleLength

    it 'has added second resource' do
      resource = dro.structural.contains[1]
      expect(resource.label).to eq 'Full PDF'
      expect(resource.structural.contains.length).to be 1
      expect(resource.structural.contains[0].filename).to eq "#{bare_druid}.pdf"
    end

    it 'has added third resource' do
      resource = dro.structural.contains[2]
      expect(resource.label).to eq 'Plain text OCR (uncorrected)'
      expect(resource.structural.contains.length).to be 1
      expect(resource.structural.contains[0].filename).to eq "#{bare_druid}.txt"
    end
  end

  context 'when there are multiple images' do
    let(:item_type) { Cocina::Models::ObjectType.image }
    let(:resource_type) { Cocina::Models::FileSetType.image }

    let(:original_resources) do
      [
        {
          externalIdentifier: "#{bare_druid}_1",
          label: 'Fileset 1',
          type: resource_type,
          version: 1,
          structural: {
            contains: [
              {
                externalIdentifier: "#{bare_druid}_1",
                label: 'Page 1',
                type: Cocina::Models::ObjectType.file,
                version: 1,
                filename: 'image1.tif',
                hasMimeType: 'image/tiff'
              }
            ]
          }
        },
        {
          externalIdentifier: "#{bare_druid}_2",
          label: 'Fileset 2',
          type: resource_type,
          version: 1,
          structural: {
            contains: [
              {
                externalIdentifier: "#{bare_druid}_2",
                label: 'Page 2',
                type: Cocina::Models::ObjectType.file,
                version: 1,
                filename: 'image2.tif',
                hasMimeType: 'image/tiff'
              }
            ]
          }
        }
      ]
    end

    before do
      create_txt_file('image1.txt')
      create_xml_file('image1.xml')
      create_txt_file('image2.txt')
      create_xml_file('image2.xml')
      create_pdf_file("#{bare_druid}.pdf")
      create_txt_file("#{bare_druid}.txt")
      create_txt_file('some_new_file.txt')

      described_class.update(dro:)
    end

    it 'has expected number of resources' do
      expect(dro.structural.contains.length).to eq 5
    end

    it 'has first resource set correctly' do
      resource = dro.structural.contains[0]
      expect(resource.structural.contains[0].filename).to eq 'image1.tif'
      expect(resource.structural.contains[1].filename).to eq 'image1.txt'
      expect(resource.structural.contains[2].filename).to eq 'image1.xml'
    end

    it 'has second resource set correctly' do
      resource = dro.structural.contains[1]
      expect(resource.structural.contains[0].filename).to eq 'image2.tif'
      expect(resource.structural.contains[1].filename).to eq 'image2.txt'
      expect(resource.structural.contains[2].filename).to eq 'image2.xml'
    end

    it 'has .pdf set correctly' do
      resource = dro.structural.contains[2]
      expect(resource.structural.contains[0].filename).to eq "#{bare_druid}.pdf"
    end

    it 'has .txt set correctly' do
      resource = dro.structural.contains[3]
      expect(resource.structural.contains[0].filename).to eq "#{bare_druid}.txt"
    end

    it 'has a new resource .txt set correctly' do
      resource = dro.structural.contains[4]
      expect(resource.structural.contains[0].filename).to eq 'some_new_file.txt'
    end
  end

  context 'when it is a book' do
    let(:item_type) { Cocina::Models::ObjectType.book }
    let(:resource_type) { Cocina::Models::FileSetType.page }

    let(:original_resources) do
      [
        {
          externalIdentifier: "#{bare_druid}_1",
          label: 'Page 1',
          type: resource_type,
          version: 1,
          structural: {
            contains: [
              {
                externalIdentifier: "https://cocina.sul.stanford.edu/file/#{bare_druid}_001",
                label: 'page_001.tif',
                type: Cocina::Models::ObjectType.file,
                version: 1,
                filename: 'page_001.tif',
                hasMimeType: 'image/tiff'
              }
            ]
          }
        },
        {
          externalIdentifier: "#{bare_druid}_2",
          label: 'Page 2',
          type: resource_type,
          version: 1,
          structural: {
            contains: [
              {
                externalIdentifier: "https://cocina.sul.stanford.edu/file/#{bare_druid}_002",
                label: 'page_002.tif',
                type: Cocina::Models::ObjectType.file,
                version: 1,
                filename: 'page_002.tif',
                hasMimeType: 'image/tiff'
              }
            ]
          }
        }
      ]
    end

    before do
      create_txt_file('page_001.txt')
      create_xml_file('page_001.xml')
      create_txt_file('page_002.txt')
      create_xml_file('page_002.xml')
      create_pdf_file("#{bare_druid}.pdf")
      create_txt_file("#{bare_druid}.txt")

      described_class.update(dro:)
    end

    it 'has expected number of resources' do
      expect(dro.structural.contains.length).to eq 4
    end

    it 'has first resource set correctly' do
      resource = dro.structural.contains[0]
      expect(resource.structural.contains[0].filename).to eq 'page_001.tif'
      expect(resource.structural.contains[1].filename).to eq 'page_001.txt'
      expect(resource.structural.contains[2].filename).to eq 'page_001.xml'
    end

    it 'has second resource set correctly' do
      resource = dro.structural.contains[1]
      expect(resource.structural.contains[0].filename).to eq 'page_002.tif'
      expect(resource.structural.contains[1].filename).to eq 'page_002.txt'
      expect(resource.structural.contains[2].filename).to eq 'page_002.xml'
    end

    it 'has third resource set correctly' do
      resource = dro.structural.contains[2]
      expect(resource.label).to eq 'Full PDF'
      expect(resource.type).to eq Cocina::Models::FileSetType.object
      expect(resource.structural.contains[0].filename).to eq "#{bare_druid}.pdf"
    end

    it 'has fourth resource set correctly' do
      resource = dro.structural.contains[3]
      expect(resource.label).to eq 'Plain text OCR (uncorrected)'
      expect(resource.type).to eq Cocina::Models::FileSetType.object
      expect(resource.structural.contains[0].filename).to eq "#{bare_druid}.txt"
    end
  end

  context 'when it is a document' do
    let(:item_type) { Cocina::Models::ObjectType.document }
    let(:resource_type) { Cocina::Models::FileSetType.document }

    let(:original_resources) do
      [
        {
          externalIdentifier: "#{bare_druid}_1",
          label: 'Page 1',
          type: resource_type,
          version: 1,
          structural: {
            contains: [
              {
                externalIdentifier: "https://cocina.sul.stanford.edu/file/#{bare_druid}_001",
                label: 'doc.pdf',
                type: Cocina::Models::ObjectType.file,
                version: 1,
                filename: 'doc.pdf',
                hasMimeType: 'application/pdf'
              }
            ]
          }
        }
      ]
    end

    before do
      create_pdf_file("#{bare_druid}.pdf")

      described_class.update(dro:)
    end

    it 'has expected number of resources' do
      expect(dro.structural.contains.length).to eq 2
    end

    it 'has first resource set correctly' do
      resource = dro.structural.contains[0]
      expect(resource.structural.contains.length).to eq 1
      expect(resource.structural.contains[0].filename).to eq 'doc.pdf'
    end

    it 'has second resource set correctly' do
      resource = dro.structural.contains[1]
      expect(resource.structural.contains.length).to eq 1
      expect(resource.label).to eq 'PDF (with automated OCR)'
      expect(resource.type).to eq Cocina::Models::FileSetType.document
      expect(resource.structural.contains[0].filename).to eq "#{bare_druid}-generated.pdf"
    end
  end

  context 'when existing files can be overwritten' do
    let(:item_type) { Cocina::Models::ObjectType.image }
    let(:resource_type) { Cocina::Models::FileSetType.image }

    let(:original_resources) do
      [
        {
          externalIdentifier: "#{bare_druid}_1",
          label: 'Page 1',
          type: resource_type,
          version: 1,
          structural: {
            contains: [
              {
                externalIdentifier: "https://cocina.sul.stanford.edu/file/#{bare_druid}_001",
                label: 'page1.tif',
                type: Cocina::Models::ObjectType.file,
                version: 1,
                filename: 'page1.tif',
                hasMimeType: 'image/tiff',
                hasMessageDigests: [
                  {
                    type: 'md5',
                    digest: 'bogus_md5'
                  },
                  {
                    type: 'sha1',
                    digest: 'bogus_sha1'
                  }
                ]
              },
              {
                externalIdentifier: "https://cocina.sul.stanford.edu/file/#{bare_druid}_001",
                label: 'page1.xml',
                type: Cocina::Models::ObjectType.file,
                version: 1,
                filename: 'page1.xml',
                hasMimeType: 'application/xml',
                use: 'transcription',
                sdrGeneratedText: sdr_generated_text,
                correctedForAccessibility: corrected_for_accessibility,
                hasMessageDigests: [
                  {
                    type: 'md5',
                    digest: 'bogus_md5'
                  },
                  {
                    type: 'sha1',
                    digest: 'bogus_sha1'
                  }
                ]
              }
            ]
          }
        }
      ]
    end

    let(:workspace_content_file) { File.join(workspace_content_dir, 'page1.xml') }

    before do
      create_xml_file('page1.xml')

      described_class.update(dro:)
    end

    context 'when existing ocr was SDR generated and has not been corrected' do
      let(:sdr_generated_text) { true }
      let(:corrected_for_accessibility) { false }

      it 'did not add a new file to the resource, instead replaced it' do
        expect(dro.structural.contains[0].structural.contains.length).to eq 2
        expect(dro.structural.contains[0].structural.contains[1].label).to eq 'page1.xml' # this is the first page
        # but the externalIdentifier and shas should be different than the original in our mocked cocina above
        expect(dro.structural.contains[0].structural.contains[1].externalIdentifier).not_to eq "https://cocina.sul.stanford.edu/file/#{bare_druid}_001"
        expect(dro.structural.contains[0].structural.contains[1].hasMessageDigests[0].attributes).not_to eq({ type: 'md5', digest: 'bogus_md5' })
        expect(dro.structural.contains[0].structural.contains[1].hasMessageDigests[1].attributes).not_to eq({ type: 'sha1', digest: 'bogus_sha1' })
      end

      it 'did not delete the OCR file in the workspace' do
        expect(File.exist?(workspace_content_file)).to be true
      end
    end

    context 'when existing ocr has been corrected' do
      let(:sdr_generated_text) { true }
      let(:corrected_for_accessibility) { true }

      it 'did not add a new file to the resource' do
        expect(dro.structural.contains[0].structural.contains.length).to eq 2
        expect(dro.structural.contains[0].structural.contains[1].label).to eq 'page1.xml' # this is the first page
        # the externalIdentifier and shas are the same as the original in our mocked cocina above
        expect(dro.structural.contains[0].structural.contains[1].externalIdentifier).to eq "https://cocina.sul.stanford.edu/file/#{bare_druid}_001"
        expect(dro.structural.contains[0].structural.contains[1].hasMessageDigests[0].attributes).to eq({ type: 'md5', digest: 'bogus_md5' })
        expect(dro.structural.contains[0].structural.contains[1].hasMessageDigests[1].attributes).to eq({ type: 'sha1', digest: 'bogus_sha1' })
      end

      it 'removed the OCR file from the workspace' do
        expect(File.exist?(workspace_content_file)).to be false
      end
    end

    context 'when existing ocr was not sdr generated' do
      let(:sdr_generated_text) { false }
      let(:corrected_for_accessibility) { false }

      it 'did not add a new file to the resource' do
        expect(dro.structural.contains[0].structural.contains.length).to eq 2
      end

      it 'removed the OCR file from the workspace' do
        expect(File.exist?(workspace_content_file)).to be false
      end
    end
  end

  context 'when existing files include item level pdf and txt' do
    let(:item_type) { Cocina::Models::ObjectType.image }
    let(:resource_type) { Cocina::Models::FileSetType.image }
    let(:sdr_generated_text) { true }
    let(:corrected_for_accessibility) { false }

    let(:original_resources) do
      [
        {
          externalIdentifier: "#{bare_druid}_1",
          label: 'Page 1',
          type: resource_type,
          version: 1,
          structural: {
            contains: [
              {
                externalIdentifier: "https://cocina.sul.stanford.edu/file/#{bare_druid}_001",
                label: 'page1.tif',
                type: Cocina::Models::ObjectType.file,
                version: 1,
                filename: 'page1.tif',
                hasMimeType: 'image/tiff',
                hasMessageDigests: [
                  {
                    type: 'md5',
                    digest: 'bogus_md5'
                  },
                  {
                    type: 'sha1',
                    digest: 'bogus_sha1'
                  }
                ]
              }
            ]
          }
        },
        {
          externalIdentifier: "#{bare_druid}_2",
          label: 'Full PDF',
          type: Cocina::Models::FileSetType.object,
          version: 1,
          structural: {
            contains: [
              {
                externalIdentifier: "https://cocina.sul.stanford.edu/file/#{bare_druid}_002",
                label: "#{bare_druid}.pdf",
                type: Cocina::Models::ObjectType.file,
                version: 1,
                filename: "#{bare_druid}.pdf",
                hasMimeType: 'application/pdf',
                sdrGeneratedText: sdr_generated_text,
                correctedForAccessibility: corrected_for_accessibility,
                hasMessageDigests: [
                  {
                    type: 'md5',
                    digest: '007dde971e903caeadf868c12701c6eb'
                  },
                  {
                    type: 'sha1',
                    digest: '2324cf4b602e0b35c013c60f726c93425813d177'
                  }
                ]
              }
            ]
          }
        },
        {
          externalIdentifier: "#{bare_druid}_3",
          label: 'Plain text OCR (uncorrected)',
          type: Cocina::Models::FileSetType.object,
          version: 1,
          structural: {
            contains: [
              {
                externalIdentifier: "https://cocina.sul.stanford.edu/file/#{bare_druid}_003",
                label: "#{bare_druid}.txt",
                type: Cocina::Models::ObjectType.file,
                version: 1,
                filename: "#{bare_druid}.txt",
                sdrGeneratedText: sdr_generated_text,
                correctedForAccessibility: corrected_for_accessibility,
                hasMimeType: 'text/plain',
                hasMessageDigests: [
                  {
                    type: 'md5',
                    digest: '007dde971e903caeadf868c12701c6eb'
                  },
                  {
                    type: 'sha1',
                    digest: '2324cf4b602e0b35c013c60f726c93425813d177'
                  }
                ]
              }
            ]
          }
        }
      ]
    end

    before do
      create_xml_file('page1.xml')
      create_pdf_file("#{bare_druid}.pdf")
      create_txt_file("#{bare_druid}.txt")

      described_class.update(dro:)
    end

    it 'did not create new resources for the .txt and .pdf files' do
      expect(dro.structural.contains.length).to eq 3
    end

    it 'updated the pdf file with latest content' do
      expect(dro.structural.contains[1].structural.contains[0].hasMessageDigests[0].digest).to eq('c2efa63399a94c7d77dc5dba28feb79e')
      expect(dro.structural.contains[1].structural.contains[0].hasMessageDigests[1].digest).to eq('1e7cedba14bc2687cd520943d2ebbe939e79b8b2')
    end

    it 'updated the text file with the latest content' do
      expect(dro.structural.contains[2].structural.contains[0].hasMessageDigests[0].digest).to eq('6d98df7e7b6faa698f3458714e2d0eee')
      expect(dro.structural.contains[2].structural.contains[0].hasMessageDigests[1].digest).to eq('8dbc9709e00f49523566107de23e4e603aab5f70')
    end
  end
end
