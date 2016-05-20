require 'spec_helper'

describe CurationConcerns::GenericWorkForm do
  let(:work) { GenericWork.new }
  let(:form) { described_class.new(work, nil) }

  describe "#required_fields" do
    subject { form.required_fields }
    it { is_expected.to eq [:title, :creator, :keyword, :rights] }
  end

  describe "#primary_terms" do
    subject { form.primary_terms }
    it { is_expected.to eq [:title, :creator, :keyword, :rights] }
  end

  describe "#secondary_terms" do
    subject { form.secondary_terms }
    it { is_expected.not_to include(:title, :creator, :keyword, :rights,
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
      context "when the model has collection ids" do
        before do
          allow(work).to receive(:in_collection_ids).and_return(['col1', 'col2'])
        end
        # This allows the edit form to show collections the work is already a member of.
        it { is_expected.to eq ['col1', 'col2'] }
      end
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
      keyword: ['derp'],
      rights: ['http://creativecommons.org/licenses/by/3.0/us/'],
      collection_ids: ['123456', 'abcdef']
    ) }

    subject { described_class.model_attributes(params) }

    it 'permits parameters' do
      expect(subject['title']).to eq ['foo']
      expect(subject['description']).to be_empty
      expect(subject['visibility']).to eq 'open'
      expect(subject['rights']).to eq ['http://creativecommons.org/licenses/by/3.0/us/']
      expect(subject['keyword']).to eq ['derp']
      expect(subject['collection_ids']).to eq ['123456', 'abcdef']
    end

    context '.model_attributes' do
      let(:params) { ActionController::Parameters.new(
        title: [''],
        description: [''],
        keyword: [''],
        rights: [''],
        collection_ids: [''],
        on_behalf_of: 'Melissa'
      ) }

      it 'removes blank parameters' do
        expect(subject['title']).to be_empty
        expect(subject['description']).to be_empty
        expect(subject['rights']).to be_empty
        expect(subject['keyword']).to be_empty
        expect(subject['collection_ids']).to be_empty
        expect(subject['on_behalf_of']).to eq 'Melissa'
      end
    end
  end

  describe "#visibility" do
    subject { form.visibility }
    it { is_expected.to eq 'restricted' }
  end

  subject { form }

  it { is_expected.to delegate_method(:on_behalf_of).to(:model) }
  it { is_expected.to delegate_method(:depositor).to(:model) }
  it { is_expected.to delegate_method(:permissions).to(:model) }

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
