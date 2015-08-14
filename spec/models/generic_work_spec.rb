require 'spec_helper'

# This tests the GenericWork model that is inserted into the host app by curation_concerns:models:install
# It includes the CurationConcerns::GenericWorkBehavior module and nothing else
# So this test covers both the GenericWorkBehavior module and the generated GenericWork model
describe GenericWork do
  it 'has a title' do
    subject.title = ['foo']
    expect(subject.title).to eq ['foo']
  end

  context 'with attached files' do
    subject { FactoryGirl.create(:work_with_files) }

    it 'has two files' do
      expect(subject.generic_files.size).to eq 2
      expect(subject.generic_files.first).to be_kind_of GenericFile
    end
  end

  describe '#indexer' do
    subject { described_class.indexer }
    it { is_expected.to eq CurationConcerns::GenericWorkIndexingService }
  end

  describe 'to_solr' do
    subject { FactoryGirl.build(:work, date_uploaded: Date.today).to_solr }
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
end
