# frozen_string_literal: true
RSpec.describe Hyrax::CustomQueries::Navigators::ChildFileSetsNavigator, :active_fedora, :clean_repo do
  subject(:factory) { Wings::ModelTransformer.new(pcdm_object: pcdm_object) }
  let(:resource) { subject.build }
  let(:custom_query_service) { Hyrax.custom_queries }

  let(:work1)    { build(:work, id: 'wk1', title: ['Work 1']) }
  let(:work2)    { build(:work, id: 'wk2', title: ['Child Work 1']) }
  let(:work3)    { build(:work, id: 'wk3', title: ['Child Work 2']) }
  let(:fileset1) { build(:file_set, id: 'fs1', title: ['Child File Set 1']) }
  let(:fileset2) { build(:file_set, id: 'fs2', title: ['Child File Set 2']) }

  describe '#find_child_file_sets' do
    let(:pcdm_object) { work1 }
    let(:work1_resource) { resource }

    before do
      work1.members = [work2, work3, fileset1, fileset2]
      work1.save!
    end

    it 'returns only child filesets as Valkyrie resources' do
      child_filesets = custom_query_service.find_child_file_sets(resource: work1_resource)
      expect(child_filesets.map(&:id)).to match_valkyrie_ids_with_active_fedora_ids([fileset1.id, fileset2.id])
    end
  end

  describe '#find_child_file_set_ids' do
    let(:pcdm_object) { work1 }
    let(:work1_resource) { resource }

    before do
      work1.members = [work2, work3, fileset1, fileset2]
      work1.save!
    end

    it 'returns Valkyrie ids for child filesets only' do
      child_fileset_ids = custom_query_service.find_child_file_set_ids(resource: work1_resource)
      expect(child_fileset_ids).to match_valkyrie_ids_with_active_fedora_ids([fileset1.id, fileset2.id])
    end
  end
end
