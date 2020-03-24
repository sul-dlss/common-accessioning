# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::EtdSubmit::SubmitMarc do
  describe 'Exporting MARC' do
    def setup
      @robot = described_class.new
      @mock_workitem = double('submit_marc_workitem')
      allow(@mock_workitem).to receive(:druid).and_return('druid:cd950rh5120')
    end

    def cleanup
      mock_workitem = double('populate_metadata_workitem')
      allow(mock_workitem).to receive(:druid).and_return('druid:jc837rq9922')

      # Make sure we're starting with a blank object
      obj = ActiveFedora::Base.load_instance(mock_workitem.druid)
      obj&.delete if obj.persisted?
    end

    describe 'basic behavior' do
      it 'can be created' do
        r = described_class.new
        expect(r).to be_instance_of(described_class)
      end

      it "creates a tmp directory in marc_workspace if it doesn't exist" do
        expect(File).to receive(:exist?).with(Settings.marc_workspace).and_return(false)
        expect(FileUtils).to receive(:mkdir).with(Settings.marc_workspace)

        described_class.new
      end
    end

    # describe '#generate_marc' do
    #   before do
    #     setup
    #   end

    #   it 'returns a MARC record' do
    #     skip
    #     # result = @robot.generate_marc(@mock_workitem.druid)
    #     # result.should be_instance_of(MARC::Record)
    #   end

    #   it 'returns a MARC record that fits the spec' do
    #     skip
    #     # specMarc = IO.read("spec/fixtures/druid_cd950rh5120/druid_cd950rh5120.marc")
    #     #
    #     # t = Time.parse('2010/07/23')
    #     # Time.should_receive(:now).and_return(t)
    #     #
    #     # result = @robot.generate_marc(@mock_workitem.druid)
    #     #
    #     # result.to_marc.should == specMarc.to_s
    #   end
    # end

    #        it "should straighten all smart quotes/apostrophis and convert em dashes to double hypens " do
    #
    #          abstract_corrected = "The process of youth development, or an adolescent's pathway to young adulthood, spans multiple domains -- cognitive, physical, social, and emotional -- and calls for an equally comprehensive approach to framing and addressing youth issues. Community-level stakeholders and systems are ideally positioned to deliver the holistic, coordinated resources that positive youth development requires; it is here, in these local settings, that young people can access the kind of services, supports, and opportunities that promote long-term wellbeing. In the ideal, young people growing up in a community supportive of youth development would benefit from educational opportunities, health and human services, recreational activities, and other resources that were both comprehensive and integrated. However, the core concepts of positive youth development can be difficult to communicate in a clear and succinct manner. Also, the systems that serve young people tend to function independently of each other. And, in the policy arena, young people are disadvantaged by negative stereotypes and the fact that they wield no political power, especially if they are poor. As a result, most communities provide limited or unaligned resources for youth and focus instead on addressing specific youth problems or deficits. In this study, I focused on community collaboratives and their potential to reshape local attitudes and approaches to youth. A structured and intentional process of collaboration can build civic capacity to support a comprehensive array of resources for young people by introducing a shared vision that emphasizes youth development as a critical dimension of community well being, securing political will for communitywide reforms that enhance youth development, and reinforcing collective decision-making to coordinate the delivery of supportive services. I asked: How did aspects of community context facilitate the emergence of community collaboratives? To what extent and under what conditions did community collaboratives generate civic capacity to support youth development? Did community collaboratives mobilize community support in ways that contributed to their own sustainability? Interviews, observations, and record data from California collaboratives in Daly City, Redwood City, and the South Coast region informed my analysis and highlighted three critical inputs for collaborative work: structural support from a local institution, local stakeholders who are willing to lead collaborative work, and pre-existing interagency relationships. I also found that embedding the collaborative structure within public agencies, asking public leaders to own collaborative work, and facilitating multi-sector dialogue helped to build civic capacity for youth development. And I saw that civic capacity contributed to sustainability by establishing a broad leadership base, creating a clear succession plan, facilitating joint budgeting, and providing a way to engage key stakeholders in redefining collaborative priorities. These findings contribute to a deeper understanding of how collaboratives can change the way that communities frame and address youth issues, opportunities and resources. They also have practical implications for practitioners, policymakers, and funders who wish to support collaborative work. First, new or emerging collaboratives may benefit from organizational capacity-building, leadership development, and efforts to secure organizational-level commitments during the early stages of collaborative work. Also, this study underscores the need to maximize the particular contributions of different stakeholder groups: public stakeholders wield influence and resources while grassroots involvement confers legitimacy. And, the cases suggest that collaborative founders or funders should anticipate sustainability issues from the outset and use civic capacity to their advantage by structuring their work in a way that renews and reinforces the elements of civic capacity over time."
    #          title_corrected =  "Community Collaborative's -- Building Civic Capacity for Youth Development"
    #
    #          druid="druid:mj580vg3369"
    #
    #          marc = EtdSubmit::SubmitMarc.create_marc(druid)
    #
    #          marc['520'].value.should ==  abstract_corrected
    #          marc['245']['a'].should == title_corrected
    #
    #        end
    #
    #        it "should use refer to <department> values of 'Education' as a school, not departments in 500 and 710 $d fields" do
    #
    #          five_hundred = "Submitted to the School of Education."
    #          seven_ten_d = "School of Education."
    #
    #          druid="druid:mj580vg3369"
    #          DorService.should_receive(:get_datastream).with(druid, 'properties').and_return(IO.read('spec/fixtures/druid_mj580vg3369/properties_department_education.xml'))
    #          DorService.should_receive(:get_datastream).with(druid, 'readers').and_return(IO.read('spec/fixtures/druid_mj580vg3369/readers.xml'))
    #
    #          marc = EtdSubmit::SubmitMarc.create_marc(druid)
    #
    #          marc['500'].value.should == five_hundred
    #          marc['710']['b'].should == seven_ten_d
    #
    #        end
    #
    #
    #
    #       it "should use refer to <department> values of 'Business' as a school, not departments in 500 and 710 $d fields" do
    #
    #          five_hundred = "Submitted to the School of Business."
    #          seven_ten_d = "School of Business."
    #
    #          druid="druid:mj580vg3369"
    #          DorService.should_receive(:get_datastream).with(druid, 'properties').and_return(IO.read('spec/fixtures/druid_mj580vg3369/properties_department_business.xml'))
    #          DorService.should_receive(:get_datastream).with(druid, 'readers').and_return(IO.read('spec/fixtures/druid_mj580vg3369/readers.xml'))
    #
    #          marc = EtdSubmit::SubmitMarc.create_marc(druid)
    #
    #          marc['500'].value.should == five_hundred
    #          marc['710']['b'].should == seven_ten_d
    #
    #       end
    #
    #         it "should use refer to <department> values of 'Law' as a school, not departments in 500 and 710 $d fields" do
    #
    #          five_hundred = "Submitted to the School of Law."
    #          seven_ten_d = "School of Law."
    #
    #          druid="druid:mj580vg3369"
    #          DorService.should_receive(:get_datastream).with(druid, 'properties').and_return(IO.read('spec/fixtures/druid_mj580vg3369/properties_department_law.xml'))
    #          DorService.should_receive(:get_datastream).with(druid, 'readers').and_return(IO.read('spec/fixtures/druid_mj580vg3369/readers.xml'))
    #
    #          marc = EtdSubmit::SubmitMarc.create_marc(druid)
    #
    #          marc['500'].value.should == five_hundred
    #          marc['710']['b'].should == seven_ten_d
    #
    #         end
    #
    #
    #
  end

  describe '#parse_name' do
    let(:parsed_name) { described_class.new.send(:parse_name, unparsed_name) }

    context 'when first last' do
      let(:unparsed_name) { 'Ludwig Wittgenstein' }

      it 'returns first last' do
        expect(parsed_name).to eq('Ludwig Wittgenstein')
      end
    end

    context 'when last, first' do
      let(:unparsed_name) { 'Wittgenstein, Ludwig' }

      it 'returns first last' do
        expect(parsed_name).to eq('Ludwig Wittgenstein')
      end
    end

    context 'when last suffix, first' do
      let(:unparsed_name) { 'Wittgenstein Jr., Ludwig' }

      it 'returns first last, suffix' do
        expect(parsed_name).to eq('Ludwig Wittgenstein, Jr.')
      end
    end
  end
end
