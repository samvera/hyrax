# frozen_string_literal: true
RSpec.describe Hyrax::CustomQueries::Navigators::ChildWorksNavigator, :clean_repo do
  let(:custom_query_service) { Hyrax.custom_queries }

  let(:collection1)    { valkyrie_create(:hyrax_collection, title: ['Collection 1']) }
  let(:collection2)    { valkyrie_create(:hyrax_collection, title: ['Child Collection 1']) }
  let(:collection3)    { valkyrie_create(:hyrax_collection, title: ['Child Collection 2']) }
  let(:work1)    { valkyrie_create(:hyrax_work, title: ['Work 1']) }
  let(:work2)    { valkyrie_create(:hyrax_work, title: ['Child Work 1']) }
  let(:work3)    { valkyrie_create(:hyrax_work, title: ['Child Work 2']) }
  let(:fileset1) { valkyrie_create(:hyrax_file_set, title: ['Child File Set 1']) }
  let(:fileset2) { valkyrie_create(:hyrax_file_set, title: ['Child File Set 2']) }

  describe '#find_child_works' do
    context 'on a collection' do
      before do
        collection1.member_ids = [collection2.id, collection3.id, work2.id, work1.id]
        Hyrax.persister.save(resource: collection1)
      end

      it 'returns only child works as Valkyrie resources' do
        child_works = custom_query_service.find_child_works(resource: collection1)
        expect(child_works.map(&:id)).to match_array([work2.id, work1.id])
      end
    end

    context 'on a work' do
      before do
        work1.member_ids = [work2.id, work3.id, fileset1.id, fileset2.id]
        Hyrax.persister.save(resource: work1)
      end

      it 'returns only child works as Valkyrie resources' do
        child_works = custom_query_service.find_child_works(resource: work1)
        expect(child_works.map(&:id)).to match_array([work2.id, work3.id])
      end
    end
  end

  describe '#find_child_work_ids' do
    context 'on a collection' do
      before do
        collection1.member_ids = [collection2.id, collection3.id, work2.id, work1.id]
        Hyrax.persister.save(resource: collection1)
      end

      it 'returns Valkyrie ids for child works only' do
        child_work_ids = custom_query_service.find_child_work_ids(resource: collection1)
        expect(child_work_ids).to match_array([work2.id, work1.id])
      end
    end

    context 'on a work' do
      before do
        work1.member_ids = [work2.id, work3.id, fileset1.id, fileset2.id]
        Hyrax.persister.save(resource: work1)
      end

      it 'returns Valkyrie ids for child works only' do
        child_work_ids = custom_query_service.find_child_work_ids(resource: work1)
        expect(child_work_ids).to match_array([work2.id, work3.id])
      end
    end
  end
end
