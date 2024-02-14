# frozen_string_literal: true
RSpec.describe Hyrax::CustomQueries::Navigators::ChildFileSetsNavigator, :clean_repo do
  let(:custom_query_service) { Hyrax.custom_queries }

  let(:work1)    { valkyrie_create(:hyrax_work, title: ['Work 1']) }
  let(:work2)    { valkyrie_create(:hyrax_work, title: ['Child Work 1']) }
  let(:work3)    { valkyrie_create(:hyrax_work, title: ['Child Work 2']) }
  let(:fileset1) { valkyrie_create(:hyrax_file_set, title: ['Child File Set 1']) }
  let(:fileset2) { valkyrie_create(:hyrax_file_set, title: ['Child File Set 2']) }

  before do
    work1.member_ids = [work2.id, work3.id, fileset1.id, fileset2.id]
    Hyrax.persister.save(resource: work1)
  end

  describe '#find_child_file_sets' do
    it 'returns only child filesets as Valkyrie resources' do
      child_filesets = custom_query_service.find_child_file_sets(resource: work1)
      expect(child_filesets.map(&:id)).to match_array([fileset1.id, fileset2.id])
    end
  end

  describe '#find_child_file_set_ids' do
    it 'returns Valkyrie ids for child filesets only' do
      child_fileset_ids = custom_query_service.find_child_file_set_ids(resource: work1)
      expect(child_fileset_ids).to match_array([fileset1.id, fileset2.id])
    end
  end
end
