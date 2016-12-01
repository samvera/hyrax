describe Sufia::Forms::WorkForm, :no_clean do
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

  describe ".build_permitted_params" do
    before do
      allow(described_class).to receive(:model_class).and_return(GenericWork)
    end
    subject { described_class.build_permitted_params }
    context "without mediated deposit" do
      it { is_expected.to include(permissions_attributes: [:type, :name, :access, :id, :_destroy]) }
    end
  end

  describe ".model_attributes" do
    before do
      allow(described_class).to receive(:model_class).and_return(GenericWork)
    end
    subject { described_class.model_attributes(ActionController::Parameters.new(attributes)) }

    context "when a user is granted edit access" do
      let(:attributes) { { permissions_attributes: [{ type: 'person', name: 'justin', access: 'edit' }] } }
      it { is_expected.to eq ActionController::Parameters.new(permissions_attributes: [ActionController::Parameters.new(type: 'person', name: 'justin', access: 'edit')]).permit! }
    end

    context "without permssions being set" do
      let(:attributes) { {} }
      it { is_expected.to eq ActionController::Parameters.new.permit! }
    end
  end
end
