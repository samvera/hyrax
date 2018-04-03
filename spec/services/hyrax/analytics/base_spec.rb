RSpec.describe Hyrax::Analytics::Base do
  describe '.page_report' do
    it 'is unimplemented' do
      expect { described_class.page_report("2018-02-16", '0') }.to raise_error NotImplementedError
    end
  end

  describe '.site_report' do
    it 'is unimplemented' do
      expect { described_class.site_report("2018-02-16", '0') }.to raise_error NotImplementedError
    end
  end

  describe '.filters', :clean_repo do
    context 'with existing content' do
      before do
        create(:work_with_one_file, :public)
      end

      it 'provides a listing of model paths in the current application' do
        expect(described_class.filters).to eq(["/concern/generic_works/", "/concern/file_sets/"])
      end
    end

    context 'without existing content' do
      it 'return an empty array when there are no instances of any models' do
        expect(described_class.filters).to eq([])
      end
    end
  end
end
