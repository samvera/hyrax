require 'spec_helper'

describe CurationConcerns::GenericWorkForm do
  let(:work) { GenericWork.new }
  let(:form) { described_class.new(work, nil) }

  describe "#primary_terms" do
    subject { form.primary_terms }
    it { is_expected.to eq [:title, :creator, :tag, :rights] }
  end

  describe "#secondary_terms" do
    subject { form.secondary_terms }
    it { is_expected.not_to include(:title, :creator, :tag, :rights,
                                    :visibilty, :visibility_during_embargo,
                                    :embargo_release_date, :visibility_after_embargo,
                                    :visibility_during_lease, :lease_expiration_date,
                                    :visibility_after_lease, :collection_ids) }
  end

  describe "#[]" do
    subject { form[term] }
    context "for collection_ids" do
      let(:term) { :collection_ids }
      it { is_expected.to eq [] }
    end
  end

  describe '.model_attributes' do
    let(:params) { ActionController::Parameters.new(
      title: ['foo'],
      description: [''],
      visibility: 'open',
      admin_set_id: '123',
      representative_id: '456',
      thumbnail_id: '789',
      tag: ['derp'],
      rights: ['http://creativecommons.org/licenses/by/3.0/us/'],
      collection_ids: ['123456', 'abcdef']) }

    subject { described_class.model_attributes(params) }

    it 'permits parameters' do
      expect(subject['title']).to eq ['foo']
      expect(subject['description']).to be_empty
      expect(subject['visibility']).to eq 'open'
      expect(subject['rights']).to eq ['http://creativecommons.org/licenses/by/3.0/us/']
      expect(subject['tag']).to eq ['derp']
      expect(subject['collection_ids']).to eq ['123456', 'abcdef']
    end

    context '.model_attributes' do
      let(:params) { ActionController::Parameters.new(
        title: [''],
        description: [''],
        tag: [''],
        rights: [''],
        collection_ids: [''],
        on_behalf_of: 'Melissa') }

      it 'removes blank parameters' do
        expect(subject['title']).to be_empty
        expect(subject['description']).to be_empty
        expect(subject['rights']).to be_empty
        expect(subject['tag']).to be_empty
        expect(subject['collection_ids']).to be_empty
        expect(subject['on_behalf_of']).to eq 'Melissa'
      end
    end
  end

  describe "#visibility" do
    subject { form.visibility }
    it { is_expected.to eq 'restricted' }
  end

  describe "on_behalf_of" do
    subject { form.on_behalf_of }
    it { is_expected.to be nil }
  end

  describe "#agreement_accepted" do
    subject { form.agreement_accepted }
    it { is_expected.to eq false }
  end

  context "on a work already saved" do
    before { allow(work).to receive(:new_record?).and_return(false) }
    it "defaults deposit agreement to true" do
      expect(form.agreement_accepted).to eq(true)
    end
  end
end
