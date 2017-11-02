RSpec.describe Hyrax::FileUploadChangeSet do
  include ActionDispatch::TestProcess

  describe "#sync" do
    let(:file_set) { FileSet.new }
    let(:user) { create(:user) }
    let(:change_set) { described_class.new(file_set, files: [file]) }

    before do
      change_set.sync
    end

    context 'using HTTP::UploadedFile' do
      let(:file) { fixture_file_upload('world.png', 'image/png') }

      it 'sets the label and title' do
        expect(file_set.label).to eq('world.png')
        expect(file_set.title).to eq(['world.png'])
      end

      context 'when file_set.title is empty and file_set.label is not' do
        let(:short_name) { 'Nice Short Name' }
        let(:file_set) { FileSet.new(label: short_name) }

        it "retains the object's original label and sets title" do
          expect(file_set.label).to eql(short_name)
          expect(file_set.title).to eql([short_name])
        end
      end
    end
  end
end
