require 'spec_helper'

describe CurationConcerns::Forms::WorkForm do
  before do
    class PirateShip < ActiveFedora::Base
      include CurationConcerns::BasicMetadata
      include CurationConcerns::HasRepresentative
    end

    class PirateShipForm < described_class
      self.model_class = ::PirateShip
    end
  end

  after do
    Object.send(:remove_const, :PirateShipForm)
    Object.send(:remove_const, :PirateShip)
  end

  let(:curation_concern) { create(:work_with_one_file) }
  let(:title) { curation_concern.file_sets.first.title.first }
  let(:file_id) { curation_concern.file_sets.first.id }
  let(:ability) { nil }
  let(:form) { PirateShipForm.new(curation_concern, ability) }

  describe "#files_hash" do
    subject { form.files_hash }
    it { is_expected.to eq(title => file_id) }
  end

  describe '.model_attributes' do
    let(:params) { ActionController::Parameters.new(title: ['foo'], description: [''], 'visibility' => 'open', admin_set_id: '123') }
    subject { PirateShipForm.model_attributes(params) }

    it 'permits parameters' do
      expect(subject['title']).to eq ['foo']
      expect(subject['description']).to be_empty
      expect(subject['visibility']).to eq 'open'
    end

    it 'excludes non-permitted params' do
      expect(subject).not_to have_key 'admin_set_id'
    end
  end
end
