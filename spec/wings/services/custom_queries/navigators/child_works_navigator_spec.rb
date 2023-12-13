# frozen_string_literal: true
RSpec.describe Hyrax::CustomQueries::Navigators::ChildWorksNavigator, :active_fedora, :clean_repo do
  subject(:factory) { Wings::ModelTransformer.new(pcdm_object: pcdm_object) }

  let(:resource) { subject.build }
  let(:custom_query_service) { Hyrax.custom_queries }

  let(:collection1)    { build(:collection, id: 'col1', title: ['Collection 1']) }
  let(:collection2)    { build(:collection, id: 'col2', title: ['Child Collection 1']) }
  let(:collection3)    { build(:collection, id: 'col3', title: ['Child Collection 2']) }
  let(:work1)    { build(:work, id: 'wk1', title: ['Work 1']) }
  let(:work2)    { build(:work, id: 'wk2', title: ['Child Work 1']) }
  let(:work3)    { build(:work, id: 'wk3', title: ['Child Work 2']) }
  let(:fileset1) { build(:file_set, id: 'fs1', title: ['Child File Set 1']) }
  let(:fileset2) { build(:file_set, id: 'fs2', title: ['Child File Set 2']) }

  describe '#find_child_works' do
    context 'on a collection' do
      let(:pcdm_object) { collection1 }
      let(:collection1_resource) { resource }

      before do
        collection1.members = [collection2, collection3, work2, work1]
        collection1.save!
      end

      it 'returns only child works as Valkyrie resources' do
        child_works = custom_query_service.find_child_works(resource: collection1_resource)
        expect(child_works.map(&:id)).to match_valkyrie_ids_with_active_fedora_ids([work2.id, work1.id])
      end
    end

    context 'on a work' do
      let(:pcdm_object) { work1 }
      let(:work1_resource) { resource }

      before do
        work1.members = [work2, work3, fileset1, fileset2]
        work1.save!
      end

      it 'returns only child works as Valkyrie resources' do
        child_works = custom_query_service.find_child_works(resource: work1_resource)
        expect(child_works.map(&:id)).to match_valkyrie_ids_with_active_fedora_ids([work2.id, work3.id])
      end
    end
  end

  describe '#find_child_work_ids' do
    context 'on a collection' do
      let(:pcdm_object) { collection1 }
      let(:collection1_resource) { resource }

      before do
        collection1.members = [collection2, collection3, work2, work1]
        collection1.save!
      end

      it 'returns Valkyrie ids for child works only' do
        child_work_ids = custom_query_service.find_child_work_ids(resource: collection1_resource)
        expect(child_work_ids).to match_valkyrie_ids_with_active_fedora_ids([work2.id, work1.id])
      end
    end

    context 'on a work' do
      let(:pcdm_object) { work1 }
      let(:work1_resource) { resource }

      before do
        work1.members = [work2, work3, fileset1, fileset2]
        work1.save!
      end

      it 'returns Valkyrie ids for child works only' do
        child_work_ids = custom_query_service.find_child_work_ids(resource: work1_resource)
        expect(child_work_ids).to match_valkyrie_ids_with_active_fedora_ids([work2.id, work3.id])
      end
    end
  end
end
