RSpec.describe GenericWork do
  it 'has a title' do
    subject.title = ['foo']
    expect(subject.title).to eq ['foo']
  end

  describe '#active_workflow' do
    it 'leverages "Sipity::Workflow.find_active_workflow_for"' do
      expect(Sipity::Workflow).to receive(:find_active_workflow_for)
      subject.active_workflow
    end
  end

  describe '.model_name' do
    subject { described_class.model_name.singular_route_key }

    it { is_expected.to eq 'hyrax_generic_work' }
  end

  describe ".attributes" do
    subject { described_class.attribute_names }

    it { is_expected.to include(:internal_resource, :created_at, :updated_at) }
  end

  describe "to_sipity_entity" do
    let(:state) { create(:workflow_state) }
    let(:work) { create_for_repository(:work) }

    before do
      Sipity::Entity.create!(proxy_for_global_id: work.to_global_id.to_s,
                             workflow_state: state,
                             workflow: state.workflow)
    end
    subject { work.to_sipity_entity }

    it { is_expected.to be_kind_of Sipity::Entity }
  end

  describe '#state' do
    let(:work) { described_class.new(state: inactive) }
    let(:inactive) { ::RDF::URI('http://fedora.info/definitions/1/0/access/ObjState#inactive') }

    subject { work.state }

    it { is_expected.to eq inactive }
  end

  describe '#suppressed?' do
    let(:work) { described_class.new(state: state) }

    context "when state is inactive" do
      let(:state) { ::RDF::URI('http://fedora.info/definitions/1/0/access/ObjState#inactive') }

      it 'is suppressed' do
        expect(work).to be_suppressed
      end
    end

    context "when the state is active" do
      let(:state) { ::RDF::URI('http://fedora.info/definitions/1/0/access/ObjState#active') }

      it 'is not suppressed' do
        expect(work).not_to be_suppressed
      end
    end

    context "when the state is nil" do
      let(:state) { nil }

      it 'is not suppressed' do
        expect(work).not_to be_suppressed
      end
    end
  end

  describe "delegations" do
    let(:work) { described_class.new { |gw| gw.apply_depositor_metadata("user") } }
    let(:proxy_depositor) { create(:user) }

    before do
      work.proxy_depositor = proxy_depositor.user_key
    end
    it "includes proxies" do
      expect(work).to respond_to(:relative_path)
      expect(work).to respond_to(:depositor)
      expect(work.proxy_depositor).to eq proxy_depositor.user_key
    end
  end

  it "can persist the object to fedora with a schema" do
    adapter = Valkyrie::MetadataAdapter.find(:fedora)
    subject.depositor = "test"
    output = adapter.persister.save(resource: subject)
    expect(output.depositor).to eq ["test"]
    expect(output.id).not_to be_blank
    graph = adapter.resource_factory.from_resource(resource: output)
    expect(graph.graph.query([nil, RDF::URI("http://id.loc.gov/vocabulary/relators/dpt"), nil]).first.object).to eq "test"
  end

  describe "metadata" do
    it "has descriptive metadata" do
      expect(subject).to respond_to(:relative_path)
      expect(subject).to respond_to(:depositor)
      expect(subject).to respond_to(:related_url)
      expect(subject).to respond_to(:based_near)
      expect(subject).to respond_to(:contributor)
      expect(subject).to respond_to(:creator)
      expect(subject).to respond_to(:title)
      expect(subject).to respond_to(:description)
      expect(subject).to respond_to(:publisher)
      expect(subject).to respond_to(:date_created)
      expect(subject).to respond_to(:date_uploaded)
      expect(subject).to respond_to(:date_modified)
      expect(subject).to respond_to(:subject)
      expect(subject).to respond_to(:language)
      expect(subject).to respond_to(:license)
      expect(subject).to respond_to(:resource_type)
      expect(subject).to respond_to(:identifier)
    end
  end
end
