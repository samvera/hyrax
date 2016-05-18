require 'spec_helper'

describe CurationConcerns::FileSet do
  include CurationConcerns::FactoryHelpers

  let(:file_set) { create(:file_set) }
  let(:file)     { mock_file_factory }

  subject { file_set }

  describe '::characterization_proxy' do
    subject { file_set.class.characterization_proxy }
    it { is_expected.to eq(:original_file) }
  end

  describe '::characterization_terms' do
    subject { file_set.class.characterization_terms }
    it { is_expected.to contain_exactly(:format_label, :file_size, :height, :width, :filename, :well_formed,
                                        :page_count, :file_title, :last_modified, :original_checksum, :mime_type) }
  end

  describe 'characterization_proxy' do
    subject { file_set.characterization_proxy }
    context 'when no proxy is present' do
      it { is_expected.to be_kind_of(CurationConcerns::FileSet::Characterization::NullCharacterizationProxy) }
    end

    context 'with a proxy' do
      before { allow(file_set).to receive(:original_file).and_return(file) }
      it { is_expected.to eq(file) }
    end
  end

  describe '#characterization_proxy?' do
    subject { file_set.characterization_proxy? }
    context 'when no proxy is present' do
      it { is_expected.to be false }
    end

    context 'with a proxy' do
      before { allow(file_set).to receive(:original_file).and_return(file) }
      it { is_expected.to be true }
    end
  end

  context 'with a custom proxy' do
    let(:custom_file_set) { build(:file_set) }
    before  { FileSet.characterization_proxy = :custom_proxy }
    after   { FileSet.characterization_proxy = :original_file }
    subject { custom_file_set.class.characterization_proxy }
    it      { is_expected.to eq(:custom_proxy) }
  end
end
