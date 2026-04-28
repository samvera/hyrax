# frozen_string_literal: true

require 'valkyrie/specs/shared_specs'

RSpec.describe Hyrax::Redirect do
  subject(:redirect) { described_class.new }

  it_behaves_like 'a Valkyrie::Resource' do
    let(:resource_klass) { described_class }
  end

  describe 'attributes' do
    it 'accepts a path, canonical flag, and sequence' do
      r = described_class.new(path: '/handle/12345/678', canonical: true, sequence: 0)
      expect(r.path).to eq('/handle/12345/678')
      expect(r.canonical).to be true
      expect(r.sequence).to eq(0)
    end

    it 'defaults canonical to false' do
      r = described_class.new(path: '/foo')
      expect(r.canonical).to be false
    end

    it 'allows sequence to be omitted' do
      r = described_class.new(path: '/foo')
      expect(r.sequence).to be_nil
    end
  end
end
