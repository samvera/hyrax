require 'spec_helper'

describe CurationConcerns::GenericWorkForm do
  let(:work) { stub_model(GenericWork, id: 'abc123') }
  let(:curation_concern) { create(:work) }
  let(:ability) { nil }
  let(:form) { described_class.new(curation_concern, ability) }

  describe '.model_attributes' do
    let(:params) { ActionController::Parameters.new(
      title: ['foo'],
      description: [''],
      visibility: 'open',
      admin_set_id: '123',
      representative_id: '456',
      thumbnail_id: '789',
      tag: ['derp'],
      rights: ['http://creativecommons.org/licenses/by/3.0/us/']) }
    subject { described_class.model_attributes(params) }
    it 'permits parameters' do
      expect(subject['title']).to eq ['foo']
      expect(subject['description']).to be_empty
      expect(subject['visibility']).to eq 'open'
      expect(subject['rights']).to eq ['http://creativecommons.org/licenses/by/3.0/us/']
      expect(subject['tag']).to eq ['derp']
    end
  end
end
