# frozen_string_literal: true
RSpec.describe GenericWork do
  it 'has a title' do
    subject.title = ['foo']
    expect(subject.title).to eq ['foo']
  end

  describe '.model_name' do
    subject { described_class.model_name.singular_route_key }

    it { is_expected.to eq 'hyrax_generic_work' }
  end

  describe ".properties" do
    subject { described_class.properties.keys }

    it { is_expected.to include("has_model", "create_date", "modified_date") }
  end

  describe '#state' do
    let(:work) { described_class.new(state: inactive) }
    let(:inactive) { ::RDF::URI('http://fedora.info/definitions/1/0/access/ObjState#inactive') }

    it 'is inactive' do
      expect(work.state.rdf_subject).to eq inactive
    end

    it 'allows state to be set to ActiveTriples::Resource' do
      other_work = described_class.new(state: work.state)
      expect(other_work.state.rdf_subject).to eq inactive
    end
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
