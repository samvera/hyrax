require 'spec_helper'

# This tests the GenericWork model that is inserted into the host app by curation_concerns:models:install
# It includes the CurationConcerns::GenericWorkBehavior module and nothing else
# So this test covers both the GenericWorkBehavior module and the generated GenericWork model
describe GenericWork do
  it 'has a title' do
    subject.title = ['foo']
    expect(subject.title).to eq ['foo']
  end

  describe '.model_name' do
    subject { described_class.model_name.singular_route_key }
    it { is_expected.to eq 'curation_concerns_generic_work' }
  end

  describe "to_sipity_entity" do
    let(:state) { FactoryGirl.create(:workflow_state) }
    let(:work) { create(:work) }
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
    subject { work.state.rdf_subject }
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

  describe '.valid_child_concerns' do
    it "is all registered curation concerns by default" do
      expect(described_class.valid_child_concerns).to eq [described_class]
    end
  end
  context 'with attached files' do
    subject { FactoryGirl.create(:work_with_files) }

    it 'has two file_sets' do
      expect(subject.file_sets.size).to eq 2
      expect(subject.file_sets.first).to be_kind_of FileSet
    end
  end

  describe '#indexer' do
    subject { described_class.indexer }
    it { is_expected.to eq CurationConcerns::WorkIndexer }
  end
  context "with children" do
    subject { FactoryGirl.create(:work_with_file_and_work) }
    it "can have the thumbnail set to the work" do
      subject.thumbnail = subject.ordered_members.to_a.last
      expect(subject.save).to eq true
    end
  end

  describe 'to_solr' do
    let(:work) { build(:work, date_uploaded: Date.today) }
    subject { work.to_solr }

    it 'indexes some fields' do
      expect(subject.keys).to include 'date_uploaded_dtsi'
    end

    it 'inherits (and extends) to_solr behaviors from superclass' do
      expect(subject.keys).to include(:id)
      expect(subject.keys).to include('has_model_ssim')
    end
  end

  describe '#to_partial_path' do
    let(:work) { described_class.new }
    subject { work.to_partial_path }
    it { is_expected.to eq 'curation_concerns/generic_works/generic_work' }
  end

  describe "#destroy" do
    let!(:work) { create(:work_with_files) }
    it "doesn't save the work after removing each individual file" do
      expect_any_instance_of(described_class).not_to receive(:save!)
      expect {
        work.destroy
      }.to change { FileSet.count }.by(-2)
    end
  end

  describe "#to_global_id" do
    let(:work) { described_class.new(id: '123') }
    subject { work.to_global_id }
    it { is_expected.to be_kind_of GlobalID }
  end

  describe "#in_works_ids" do
    let(:parent) { FactoryGirl.create(:generic_work) }
    subject { FactoryGirl.create(:generic_work) }
    before do
      parent.ordered_members << subject
      parent.save!
    end

    it "returns ids" do
      expect(subject.in_works_ids).to eq [parent.id]
    end
  end
end
