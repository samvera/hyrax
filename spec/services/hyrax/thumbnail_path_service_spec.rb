RSpec.describe Hyrax::ThumbnailPathService do
  include Hyrax::FactoryHelpers

  subject { described_class.call(object) }

  context "with a FileSet" do
    let(:object) { build(:file_set, id: '999') }

    before do
      allow(object).to receive(:original_file).and_return(original_file)
      # https://github.com/samvera/active_fedora/issues/1251
      allow(object).to receive(:persisted?).and_return(true)
    end
    context "that has a thumbnail" do
      let(:original_file) { mock_file_factory(mime_type: 'image/jpeg') }

      before { allow(File).to receive(:exist?).and_return(true) }
      it { is_expected.to eq '/downloads/999?file=thumbnail' }
    end

    context "that is an audio" do
      let(:original_file) { mock_file_factory(mime_type: 'audio/x-wav') }

      it { is_expected.to match %r{/assets/audio-.+.png} }
    end

    context "that has no thumbnail" do
      let(:original_file) { mock_model('MockOriginal', mime_type: nil) }

      it { is_expected.to match %r{/assets/default-.+.png} }
    end
  end

  context "with a Work" do
    context "that has a thumbnail" do
      let(:object)         { GenericWork.new(thumbnail_id: '999') }
      let(:representative) { build(:file_set, id: '999') }
      let(:original_file)  { mock_file_factory(mime_type: 'image/jpeg') }

      before do
        allow(File).to receive(:exist?).and_return(true)
        allow(ActiveFedora::Base).to receive(:find).with('999').and_return(representative)
        allow(representative).to receive(:original_file).and_return(original_file)
      end

      it { is_expected.to eq '/downloads/999?file=thumbnail' }
    end

    context "that doesn't have a representative" do
      let(:object) { FileSet.new }

      it { is_expected.to match %r{/assets/default-.+.png} }
    end
  end
end
