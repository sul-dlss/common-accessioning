# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Release::UpdateMarc do
  before :each do
    @druid = 'aa222cc3333'
    @work_item = instance_double(Dor::Item)
    @r = Robots::DorRepo::Release::UpdateMarc.new
  end

  it 'calls the update marc record method' do
    setup_release_item(@druid, :item, nil)
    expect(@release_item).to receive(:update_marc_record)
    @r.perform(@work_item)
  end
end
