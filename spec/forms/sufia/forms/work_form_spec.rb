describe Sufia::Forms::WorkForm do
  let(:work) { GenericWork.new }
  let(:form) { described_class.new(work, nil) }
  let(:works) { [GenericWork.new, FileSet.new, GenericWork.new] }
  let(:files) { [FileSet.new, GenericWork.new, FileSet.new] }

  describe "#ordered_fileset_members" do
    it "expects ordered fileset members" do
      allow(work).to receive(:ordered_members).and_return(files)
      expect(form.ordered_fileset_members.size).to eq(2)
    end
  end

  describe "#ordered_work_members" do
    it "expects ordered work members" do
      allow(work).to receive(:ordered_members).and_return(works)
      expect(form.ordered_work_members.size).to eq(2)
    end
  end
end
