# frozen_string_literal: true
RSpec.describe Hyrax::Forms::WorkForm, :active_fedora do
  let(:work) { GenericWork.new }
  let(:form) { described_class.new(work, nil, controller) }
  let(:works) { [GenericWork.new, FileSet.new, GenericWork.new] }
  let(:controller) { instance_double(Hyrax::GenericWorksController) }

  # This class is an abstract class, so we have to set model_class
  # TODO: merge with generic_work_form_spec
  before do
    allow(described_class).to receive(:model_class).and_return(GenericWork)
    allow(form).to receive(:model_class).and_return(GenericWork)
  end

  describe "#version" do
    before do
      allow(work).to receive(:etag).and_return('123456')
    end
    subject { form.version }

    it { is_expected.to eq '123456' }
  end

  describe '#in_works_ids' do
    let(:work)   { parent.members.first }
    let(:parent) { FactoryBot.create(:work_with_one_child) }

    it 'gives the ids for parent works' do
      expect(form.in_works_ids).to contain_exactly(parent.id)
    end
  end

  describe "#select_files" do
    let(:work) { create(:work_with_one_file) }
    let(:title) { work.file_sets.first.title.first }
    let(:file_id) { work.file_sets.first.id }

    subject { form.select_files }

    it { is_expected.to eq(title => file_id) }
  end

  describe '#member_of_collections' do
    subject { form.member_of_collections }

    before do
      allow(controller).to receive(:params).and_return(add_works_to_collection: collection_id)
    end

    context 'when passed nil' do
      let(:collection_id) { nil }

      it { is_expected.to be_empty }
    end

    context 'when passed a string' do
      let(:collection) { create(:collection) }
      let(:collection_id) { collection.id }

      it { is_expected.to match_array([collection]) }
    end

    context 'when member of other collections' do
      let(:collection) { create(:collection) }
      let(:collection_id) { collection.id }

      before do
        allow(work).to receive(:member_of_collections).and_return(['foo'])
      end

      it { is_expected.to match_array(['foo', collection]) }
    end
  end

  describe "#[]" do
    it 'has one element' do
      expect(form['description']).to eq ['']
    end
  end

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
    subject { described_class.build_permitted_params }

    context "without mediated deposit" do
      it {
        is_expected.to include(:add_works_to_collection,
                               :version,
                               :on_behalf_of,
                               { permissions_attributes: [:type, :name, :access, :id, :_destroy] },
                               { file_set: [:visibility, :visibility_during_embargo, :embargo_release_date, :visibility_after_embargo,
                                            :visibility_during_lease, :lease_expiration_date, :visibility_after_lease, :uploaded_file_id] },
                               based_near_attributes: [:id, :_destroy],
                               member_of_collections_attributes: [:id, :_destroy],
                               work_members_attributes: [:id, :_destroy])
      }
    end
  end

  describe ".model_attributes" do
    let(:params) { ActionController::Parameters.new(attributes) }
    let(:attributes) do
      {
        title: ['a', 'b'],
        alternative_title: ['c', 'd'],
        description: [''],
        abstract: [''],
        visibility: 'open',
        parent_id: '123',
        representative_id: '456',
        thumbnail_id: '789',
        keyword: ['penguin'],
        source: ['related'],
        rights_statement: 'http://rightsstatements.org/vocab/InC-EDU/1.0/',
        rights_notes: ['Notes on the rights'],
        license: ['http://creativecommons.org/licenses/by/3.0/us/'],
        access_right: ['Only accessible via login.']
      }
    end

    subject { described_class.model_attributes(params) }

    it 'permits metadata parameters' do
      expect(subject['title']).to eq ['a', 'b']
      expect(subject['alternative_title']).to eq ['c', 'd']
      expect(subject['description']).to be_empty
      expect(subject['abstract']).to be_empty
      expect(subject['visibility']).to eq 'open'
      expect(subject['keyword']).to eq ['penguin']
      expect(subject['source']).to eq ['related']
    end

    it 'permits rights parameters' do
      expect(subject['license']).to eq ['http://creativecommons.org/licenses/by/3.0/us/']
      expect(subject['rights_statement']).to eq 'http://rightsstatements.org/vocab/InC-EDU/1.0/'
      expect(subject['rights_notes']).to eq ['Notes on the rights']
      expect(subject['access_right']).to eq ['Only accessible via login.']
    end

    it 'excludes non-permitted params' do
      expect(subject).not_to have_key 'parent_id'
    end

    context "when a user is granted edit access" do
      let(:admin_set) { create(:admin_set) }

      context "and a admin_set that allows grants has been selected" do
        let(:attributes) { { admin_set_id: admin_set.id, permissions_attributes: [{ type: 'person', name: 'justin', access: 'edit' }] } }
        let(:permission_template) { create(:permission_template, source_id: admin_set.id) }
        let!(:workflow) { create(:workflow, allows_access_grant: true, active: true, permission_template_id: permission_template.id) }

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
        let(:permission_template) { create(:permission_template, source_id: admin_set.id) }
        let!(:workflow) { create(:workflow, allows_access_grant: false, active: true, permission_template_id: permission_template.id) }

        it { is_expected.to eq ActionController::Parameters.new(admin_set_id: admin_set.id).permit! }
      end
    end

    context "without permissions being set" do
      let(:attributes) { {} }

      it { is_expected.to eq ActionController::Parameters.new.permit! }
    end
  end

  describe "initialized fields" do
    context "for :description" do
      subject { form[:description] }

      it { is_expected.to eq [''] }
    end

    context "for :abstract" do
      subject { form[:abstract] }

      it { is_expected.to eq [''] }
    end

    context "for :embargo_release_date" do
      subject { form[:embargo_release_date] }

      it { is_expected.to be nil }
    end
  end

  describe '#visibility' do
    subject { form.visibility }

    it { is_expected.to eq 'restricted' }
  end

  describe '#primary_terms' do
    it 'contains the required fields' do
      expect(form.primary_terms).to include(*form.required_fields)
    end

    context 'with a field that is not in terms' do
      let(:bad_term) { :BadWorkFormSpecTerm }

      before { form.class.required_fields += [bad_term] }
      after  { form.class.required_fields -= [bad_term] }

      it 'logs a warning' do
        expect(Hyrax.logger).to receive(:warn).with(/#{bad_term}/)
        form.primary_terms
      end

      it 'does not include the errant term' do
        expect(form.primary_terms).not_to include bad_term
      end
    end
  end

  describe '#secondary_terms' do
    it 'does not contain the primary terms' do
      expect(form.secondary_terms).not_to include(*form.primary_terms)
    end

    context 'with a new non-primary term' do
      let(:new_term) { :WorkFormSpecTerm }

      before { form.class.terms += [new_term] }
      after  { form.class.terms -= [new_term] }

      it 'adds the term to secondary' do
        expect(form.secondary_terms).to include new_term
      end
    end
  end

  describe '#human_readable_type' do
    subject { form.human_readable_type }

    it { is_expected.to eq 'Generic Work' }
  end

  describe "#open_access?" do
    subject { form.open_access? }

    it { is_expected.to be false }
  end

  describe "#authenticated_only_access?" do
    subject { form.authenticated_only_access? }

    it { is_expected.to be false }
  end

  describe "#open_access_with_embargo_release_date?" do
    subject { form.open_access_with_embargo_release_date? }

    it { is_expected.to be false }
  end

  describe "#private_access?" do
    subject { form.private_access? }

    it { is_expected.to be true }
  end

  describe "#member_ids" do
    subject { form.member_ids }

    it { is_expected.to eq work.member_ids }
  end

  describe '#display_additional_fields?' do
    subject { form.display_additional_fields? }

    context 'with no secondary terms' do
      before do
        allow(form).to receive(:secondary_terms).and_return([])
      end
      it { is_expected.to be false }
    end
    context 'with secondary terms' do
      before do
        allow(form).to receive(:secondary_terms).and_return([:foo, :bar])
      end
      it { is_expected.to be true }
    end
  end

  describe "#embargo_release_date" do
    let(:work) { create(:work, embargo_release_date: 5.days.from_now) }

    subject { form.embargo_release_date }

    it { is_expected.to eq work.embargo_release_date }
  end

  describe "#visibility_during_embargo" do
    let(:work) { create(:work, visibility_during_embargo: 'authenticated') }

    subject { form.visibility_during_embargo }

    it { is_expected.to eq work.visibility_during_embargo }
  end

  describe "#visibility_after_embargo" do
    let(:work) { create(:work, visibility_after_embargo: 'public') }

    subject { form.visibility_after_embargo }

    it { is_expected.to eq work.visibility_after_embargo }
  end

  describe "#lease_expiration_date" do
    let(:work) { create(:work, lease_expiration_date: 2.days.from_now) }

    subject { form.lease_expiration_date }

    it { is_expected.to eq work.lease_expiration_date }
  end

  describe "#visibility_during_lease" do
    let(:work) { create(:work, visibility_during_lease: 'authenticated') }

    subject { form.visibility_during_lease }

    it { is_expected.to eq work.visibility_during_lease }
  end

  describe "#visibility_after_lease" do
    let(:work) { create(:work, visibility_after_lease: 'private') }

    subject { form.visibility_after_lease }

    it { is_expected.to eq work.visibility_after_lease }
  end

  describe ".workflow_for" do
    subject { described_class.send(:workflow_for, admin_set_id: admin_set.id) }

    context "when a active workflow is not found" do
      let(:admin_set) { create(:admin_set, with_permission_template: true) }

      it "raises a custom error" do
        expect { subject }.to raise_error Hyrax::MissingWorkflowError
      end
    end
    context "when a permission_template is not found" do
      let(:admin_set) { create(:admin_set) }

      it "raises an error" do
        expect { subject }.to raise_error(/Missing permission template for AdminSet\(id:/)
      end
    end
  end
end
