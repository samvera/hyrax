# frozen_string_literal: true

require 'valkyrie/specs/shared_specs'

RSpec.describe Hyrax::Resource do
  subject(:object) { described_class.new }

  it_behaves_like 'a Valkyrie::Resource' do
    let(:resource_klass) { described_class }
  end

  describe '#alternate_ids' do
    let(:id) { Valkyrie::ID.new('fake_identifier') }
    it 'has an attribute for alternate ids' do
      expect { object.alternate_ids = id }
        .to change { object.alternate_ids }
        .to contain_exactly id
    end
  end
end
