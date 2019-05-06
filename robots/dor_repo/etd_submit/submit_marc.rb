#!/usr/bin/env ruby
# frozen_string_literal: true

require 'models/etd'
require 'marc'
require 'fileutils'

module Robots
  module DorRepo
    module EtdSubmit
      class SubmitMarc < Robots::DorRepo::EtdSubmit::Base
        include ::EtdSubmit::RobotCronBase

        attr_reader :day_working_dir

        def initialize(opts = {})
          super('dor', 'etdSubmitWF', 'submit-marc', opts)

          FileUtils.mkdir(ROBOT_ROOT + '/tmp') unless File.exist?(ROBOT_ROOT + '/tmp')
          @day_working_dir = File.join(ROBOT_ROOT, 'tmp', Time.now.strftime('%Y%m%d'))
          @prerequisites = ['dor:etdSubmitWF:registrar-approval']
        end

        def perform(druid)
          marc = generate_marc(druid)
          output_file(druid, marc)
        end

        # Create initial MARC record. Used by #generate_marc
        def initialize_marc(druid, properties)
          marc = MARC::Record.new

          # Populate the MARC leader
          marc.leader[5] = 'n'
          marc.leader[6] = 'a'
          marc.leader[7] = 'm'
          marc.leader[9] = 'a'
          marc.leader[17] = '3'
          marc.leader[18] = 'i'

          # Add control fields
          # Skip control field 000 with updated header
          # marc.append(MARC::ControlField.new('000', "am7i n a"))
          cf001 = druid.sub('druid:', 'dor')
          marc.append(MARC::ControlField.new('001', cf001))
          marc.append(MARC::ControlField.new('006', 'm        d        '))
          marc.append(MARC::ControlField.new('007', 'cr un'))
          cf008 = Time.now.strftime('%y%m%d') + 't' + publication_year + copyright_year(properties) + 'cau     om    000 0 eng d'
          marc.append(MARC::ControlField.new('008', cf008))

          # Begin building data fields
          marc.append(MARC::DataField.new('040', ' ', ' ', %w[a CSt], %w[b eng], %w[e rda], %w[c CSt]))

          marc
        end

        # Write MARC record to latest working directory
        #
        # @param [String] druid Id of Etd being worked on
        # @param [MARC::Record] record Marc from the Etd
        # @return [void]
        def output_file(druid, record)
          FileUtils.mkdir(day_working_dir) unless File.exist?(day_working_dir)

          File.open(File.join(day_working_dir, "#{druid.tr(':', '_')}.marc"), 'w') do |f|
            writer = MARC::Writer.new(f)
            writer.write(record)
          end
        end

        def generate_marc(druid)
          etd = Etd.find(druid)

          properties = etd.datastreams['properties']
          readers = Nokogiri::XML(etd.datastreams['readers'].content)

          # Set values from properties DS
          degreeconfyr = properties.degreeconfyr.first
          name = properties.name.first

          suffix = properties.suffix.first || ''

          prefix = properties.prefix.first || ''

          title = properties.title.first
          department = properties.department.first
          schoolname = properties.schoolname.first
          abstract = properties.abstract.first
          degree = properties.degree.first
          etd_id = properties.dissertation_id.first

          # Set values needed from readers DS
          primary_advisors = readers.search('//reader[readerrole ="Advisor" or readerrole ="Co-Adv" or readerrole = "Dissertation Co-Advisor" or readerrole = "Co-Adv"]/name')
          advisors = readers.search('//reader[readerrole = "Reader" or readerrole ="Rdr" or readerrole = "Outside Reader" or readerrole = "Engineers Thesis/Project Adv"]/name')

          marc = initialize_marc(druid, properties)

          statement_of_responsibility(druid, marc, name, suffix, prefix, title)

          marc.append(MARC::DataField.new('264', ' ', '1',
                                          ['a', '[Stanford, California] :'],
                                          ['b', '[Stanford University],'],
                                          ['c', format_aacr2(degreeconfyr).to_s]))
          marc.append(MARC::DataField.new('264', ' ', '4', ['c', "©#{copyright_year(properties)}"]))

          marc.append(MARC::DataField.new('300', ' ', ' ', ['a', '1 online resource.']))

          marc.append(MARC::DataField.new('336', ' ', ' ', %w[a text], %w[2 rdacontent]))
          marc.append(MARC::DataField.new('337', ' ', ' ', %w[a computer], %w[2 rdamedia]))
          marc.append(MARC::DataField.new('338', ' ', ' ', ['a', 'online resource'], %w[2 rdacarrier]))

          unless department.nil?
            if /Business|Education|Law/.match?(department)
              marc.append(MARC::DataField.new('500', ' ', ' ', ['a', "Submitted to the School of #{format_aacr2(department)}"]))
            else
              marc.append(MARC::DataField.new('500', ' ', ' ', ['a', "Submitted to the Department of #{format_aacr2(department)}"]))
            end
          end

          marc.append(MARC::DataField.new('502', ' ', ' ',
                                          %w[g Thesis],
                                          ['b', degree.strip.to_s],
                                          ['c', 'Stanford University'],
                                          ['d', format_aacr2(degreeconfyr).to_s]))

          marc.append(MARC::DataField.new('520', '3', ' ', ['a', format_aacr2(abstract)]))

          ##========= primary advisors first, in alphabetical order ==========#
          padv = []
          primary_advisors.each do |advisor|
            padv << advisor.content
          end
          padv.sort!
          padv.each do |a|
            marc.append(MARC::DataField.new('700', '1', ' ', ['a', "#{a.strip},"], ['e', 'degree supervisor.'], %w[4 ths]))
          end
          #========= now do the same on readers, in alphabetical order ==========#
          adv = []
          advisors.each do |advisor|
            adv << advisor.content
          end
          adv.sort!
          adv.each do |a|
            marc.append(MARC::DataField.new('700', '1', ' ', ['a', "#{a.strip},"], ['e', 'degree committee member.'], %w[4 ths]))
          end

          if department.nil?
            marc.append(MARC::DataField.new('710', '2', ' ', ['a', 'Stanford University.'], ['b', "School of #{format_aacr2(schoolname)}"]))
          elsif /Business|Education|Law/.match?(department)
            #========= Business, Education and Law are schools, not departments ==========#
            marc.append(MARC::DataField.new('710', '2', ' ', ['a', 'Stanford University.'], ['b', "School of #{format_aacr2(department)}"]))
          else
            marc.append(MARC::DataField.new('710', '2', ' ', ['a', 'Stanford University.'], ['b', "Department of #{format_aacr2(department)}"]))
          end

          marc.append(MARC::DataField.new('856', '4', '0', ['u', "http://purl.stanford.edu/#{druid.gsub('druid:', '')}"]))
          marc.append(MARC::DataField.new('910', ' ', ' ', ['a', "https://etd.stanford.edu/view/#{etd_id.strip}"]))

          marc
        end

        # Add the 100 and 245 fields to the MARC record
        def statement_of_responsibility(_druid, marc, name, suffix, prefix, title)
          name_direct = parse_name(name)

          if !suffix.nil? && suffix.strip != ''
            suffix.chop! unless suffix.match(/\.$/).nil?
            name_direct << ', ' << suffix
          end

          name_direct = prefix + ' ' + name_direct if !prefix.nil? && prefix.strip != ''

          # Add names to 100 field of MARC record
          author_field = MARC::DataField.new('100', '1', ' ', ['a', "#{name},"])

          author_field.append(MARC::Subfield.new('c', "#{suffix},")) if !suffix.nil? && suffix.strip != ''

          author_field.append(MARC::Subfield.new('c', "#{prefix},")) if !prefix.nil? && prefix.strip != ''

          author_field.append(MARC::Subfield.new('e', 'author.'))
          marc.append(author_field)

          # Add name_direct to 245 MARC field
          marc.append(MARC::DataField.new('245', '1', '0', ['a', "#{filter(title)} /"], ['c', format_aacr2(name_direct)]))
        end

        # Make sure that the field has no leading/trailing whitespace and ends with a period
        def format_aacr2(text)
          text = filter(text)
          text << '.' if text.match(/\.$/).nil?
          text
        end

        # Filter out smart text and em dashes
        def filter(text)
          text.strip!
          text.gsub!(/\342\200\234|\342\200\235/, '"')
          text.gsub!(/\342\200\230|\342\200\231/, "'")
          text.gsub!(/\342\200\223/, '--')
          text.gsub!(/\342\200\246/, '...')
          text.gsub!(/\r|\n|\t/, ' ')
          if text.length > 9950
            text = text.slice!(0..9950)
            text << ' ... '
          end
          text
        end

        private

        # Use submit_date for copyright year, if available, else use degreeconfyr
        def copyright_year(properties)
          submit_date = properties.submit_date.first
          if submit_date
            Time.at(submit_date.to_i).year.to_s
          else
            properties.degreeconfyr.first
          end
        end

        # Use current year as publication year always
        def publication_year
          Time.now.year.to_s
        end

        def parse_name(name_str)
          return name_str unless /,/.match?(name_str)

          new_name_str = +name_str
          gen_suf = new_name_str.slice!(/Jr\.|Sr\.|III|IV|II/)

          new_name_str =~ /([^,\r\n]*),\s*(.*)/
          last = Regexp.last_match(1)
          first = Regexp.last_match(2)
          new_name_str = [first.strip, last.strip].join(' ').sub(',', '')
          return new_name_str if gen_suf.nil?

          "#{new_name_str}, #{gen_suf.strip}"
        end
      end
    end
  end
end
