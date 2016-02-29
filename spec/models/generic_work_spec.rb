require 'spec_helper'

# This tests the GenericWork model that is inserted into the host app by curation_concerns:models:install
# It includes the CurationConcerns::GenericWorkBehavior module and nothing else
# So this test covers both the GenericWorkBehavior module and the generated GenericWork model
describe GenericWork do
  it 'has a title' do
    subject.title = ['foo']
    expect(subject.title).to eq ['foo']
  end

  describe '.model_name' do
    subject { described_class.model_name.singular_route_key }
    it { is_expected.to eq 'curation_concerns_generic_work' }
  end

  context 'with attached files' do
    subject { FactoryGirl.create(:work_with_files) }

    it 'has two file_sets' do
      expect(subject.file_sets.size).to eq 2
      expect(subject.file_sets.first).to be_kind_of FileSet
    end
  end

  describe '#indexer' do
    subject { described_class.indexer }
    it { is_expected.to eq CurationConcerns::WorkIndexer }
  end

  describe 'to_solr' do
    subject { build(:work, date_uploaded: Date.today).to_solr }

    it 'indexes some fields' do
      expect(subject.keys).to include 'date_uploaded_dtsi'
    end

    it 'inherits (and extends) to_solr behaviors from superclass' do
      expect(subject.keys).to include(:id)
      expect(subject.keys).to include('has_model_ssim')
    end
  end

  describe '#to_partial_path' do
    let(:work) { described_class.new }
    subject { work.to_partial_path }
    it { is_expected.to eq 'curation_concerns/generic_works/generic_work' }
  end

  describe "#destroy" do
    let!(:work) { create(:work_with_files) }
    it "doesn't save the work after removing each individual file" do
      expect_any_instance_of(described_class).not_to receive(:save!)
      expect {
        work.destroy
      }.to change { FileSet.count }.by(-2)
    end
  end
end
