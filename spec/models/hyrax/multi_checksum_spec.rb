# frozen_string_literal: true

require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe Hyrax::MultiChecksum do
  describe '.for' do
    let(:file) { fixture_file_upload('world.png', 'image/png') }
    let(:valk_file) do
      Valkyrie::StorageAdapter::File.new(id: Valkyrie::ID.new('test_id'), io: ::File.open(file, 'rb'))
    end

    it 'returns a correct MultiChecksum' do
      mcs = described_class.for(valk_file)
      expect(mcs.md5).to eq '28da6259ae5707c68708192a40b3e85c'
      expect(mcs.sha1).to eq 'f794b23c0c6fe1083d0ca8b58261a078cd968967'
      expect(mcs.sha256).to eq '710f2bc3f91e17466acf266c555168588c5ff16f0642cbc783ed81114ac385d8'
    end
  end
end
