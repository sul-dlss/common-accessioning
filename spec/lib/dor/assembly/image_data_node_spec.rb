# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::Assembly::ImageDataNode do
  describe '#build' do
    subject(:build) { described_class.build(exif) }
    # rubocop:disable RSpec/VerifiedDoubles

    let(:exif) { double(MiniExiftool, image_width: 55, image_height: 66) }
    # rubocop:enable RSpec/VerifiedDoubles

    it { is_expected.to eq('<imageData width="55" height="66"/>') }
  end
end
