describe Sufia::Forms::WorkForm, :no_clean do
  let(:work) { GenericWork.new }
  let(:form) { described_class.new(work, nil) }
  let(:works) { [GenericWork.new, FileSet.new, GenericWork.new] }
  let(:files) { [FileSet.new, GenericWork.new, FileSet.new] }

  describe "#work_members" do
    subject { form.work_members }
    before do
      allow(work).to receive(:members).and_return(works)
    end
    it "expects members that are works" do
      expect(form.work_members.size).to eq(2)
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
      let(:admin_set) { create(:admin_set) }

      context "and a admin_set that allows grants has been selected" do
        let(:attributes) { { admin_set_id: admin_set.id, permissions_attributes: [{ type: 'person', name: 'justin', access: 'edit' }] } }
        before { create(:permission_template, admin_set_id: admin_set.id, workflow_name: workflow.name) }
        let(:workflow) { create(:workflow, allows_access_grant: true) }

        it do
          is_expected.to eq ActionController::Parameters.new(admin_set_id: admin_set.id,
                                                             permissions_attributes: [ActionController::Parameters.new(type: 'person', name: 'justin', access: 'edit')]).permit!
        end
      end

      context "and no admin_set has been selected" do
        let(:attributes) { { permissions_attributes: [{ type: 'person', name: 'justin', access: 'edit' }] } }
        it { is_expected.to eq ActionController::Parameters.new.permit! }
      end

      context "and an admin_set that doesn't allow grants has been selected" do
        let(:attributes) { { admin_set_id: admin_set.id, permissions_attributes: [{ type: 'person', name: 'justin', access: 'edit' }] } }
        before { create(:permission_template, admin_set_id: admin_set.id, workflow_name: workflow.name) }
        let(:workflow) { create(:workflow, allows_access_grant: false) }

        it { is_expected.to eq ActionController::Parameters.new(admin_set_id: admin_set.id).permit! }
      end
    end

    context "without permssions being set" do
      let(:attributes) { {} }
      it { is_expected.to eq ActionController::Parameters.new.permit! }
    end
  end
end
