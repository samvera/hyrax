describe Sufia::Forms::WorkForm, :no_clean do
  let(:work) { GenericWork.new }
  let(:form) { described_class.new(work, nil) }

  describe "#select_files" do
    let(:work) { create(:work_with_one_file) }
    let(:title) { work.file_sets.first.title.first }
    let(:file_id) { work.file_sets.first.id }

    subject { form.select_files }
    it { is_expected.to eq(title => file_id) }
  end

  describe "#[]" do
    it 'has one element' do
      expect(form['description']).to eq ['']
    end
  end

  describe "#ordered_fileset_members" do
    let(:files) { [FileSet.new, GenericWork.new, FileSet.new] }

    it "expects ordered fileset members" do
      allow(work).to receive(:ordered_members).and_return(files)
      expect(form.ordered_fileset_members.size).to eq(2)
    end
  end

  describe "#ordered_work_members" do
    let(:works) { [GenericWork.new, FileSet.new, GenericWork.new] }

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
    let(:params) { ActionController::Parameters.new(attributes) }
    let(:attributes) do
      {
        title: ['foo'],
        description: [''],
        visibility: 'open',
        parent_id: '123',
        representative_id: '456',
        thumbnail_id: '789',
        keyword: ['derp'],
        source: ['related'],
        rights: ['http://creativecommons.org/licenses/by/3.0/us/']
      }
    end

    before do
      allow(described_class).to receive(:model_class).and_return(GenericWork)
    end

    subject { described_class.model_attributes(params) }

    it 'permits parameters' do
      expect(subject['title']).to eq ['foo']
      expect(subject['description']).to be_empty
      expect(subject['visibility']).to eq 'open'
      expect(subject['rights']).to eq ['http://creativecommons.org/licenses/by/3.0/us/']
      expect(subject['keyword']).to eq ['derp']
      expect(subject['source']).to eq ['related']
    end

    it 'excludes non-permitted params' do
      expect(subject).not_to have_key 'parent_id'
    end

    context "without mediated deposit" do
      context "and a user is granted edit access" do
        let(:attributes) { { permissions_attributes: [{ type: 'person', name: 'justin', access: 'edit' }] } }
        it { is_expected.to eq ActionController::Parameters.new(permissions_attributes: [ActionController::Parameters.new(type: 'person', name: 'justin', access: 'edit')]).permit! }
      end
    end

    context "with mediated deposit" do
      before do
        allow(Flipflop).to receive(:enable_mediated_deposit?).and_return(true)
      end
      context "and a user is granted edit access" do
        let(:attributes) { { permissions_attributes: [{ type: 'person', name: 'justin', access: 'edit' }] } }
        it { is_expected.to eq ActionController::Parameters.new(permissions_attributes: []).permit! }
      end

      context "without permssions being set" do
        let(:attributes) { {} }
        it { is_expected.to eq ActionController::Parameters.new.permit! }
      end
    end
  end

  describe "initialized fields" do
    context "for :description" do
      subject { form[:description] }
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

  describe "#embargo_release_date" do
    let(:work) { create(:work, embargo_release_date: 5.days.from_now) }
    subject { form.embargo_release_date }
    it { is_expected.to eq work.embargo_release_date }
  end

  describe "#lease_expiration_date" do
    let(:work) { create(:work, lease_expiration_date: 2.days.from_now) }
    subject { form.lease_expiration_date }
    it { is_expected.to eq work.lease_expiration_date }
  end

  describe ".required_fields" do
    subject { described_class.required_fields }
    it { is_expected.to eq [:title, :creator, :keyword, :rights] }
  end
end
