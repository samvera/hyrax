RSpec.describe Hyrax::CustomQueries::Navigators::ParentWorksNavigator do
  subject(:factory) { Wings::ModelTransformer.new(pcdm_object: pcdm_object) }
  let(:resource) { subject.build }
  let(:custom_query_service) { Hyrax.query_service.custom_queries }

  let(:collection1)    { build(:collection, id: 'col1', title: ['Collection 1']) }
  let(:collection2)    { build(:collection, id: 'col1', title: ['Collection 1']) }
  let(:work1)    { build(:work, id: 'wk1', title: ['Work 1']) }
  let(:work2)    { build(:work, id: 'wk2', title: ['Work 2']) }
  let(:work3)    { build(:work, id: 'wk3', title: ['Child Work 1']) }
  let(:work4)    { build(:work, id: 'wk4', title: ['Child Work 2']) }
  let(:fileset1) { build(:file_set, id: 'fs1', title: ['Child File Set 1']) }
  let(:fileset2) { build(:file_set, id: 'fs2', title: ['Child File Set 2']) }

  describe '#find_parent_works' do
    context 'for a work' do
      let(:pcdm_object) { work3 }
      let(:work3_resource) { resource }

      before do
        collection1.members = [work3, work4]
        collection1.save!
        work1.members = [work3, fileset1, fileset2]
        work2.members = [work3, work4]
        work1.save!
        work2.save!
      end

      it 'returns only parent works as Valkyrie resources' do
        parent_works = custom_query_service.find_parent_works(resource: work3_resource)
        expect(parent_works.map(&:id)).to match_valkyrie_ids_with_active_fedora_ids([work2.id, work1.id])
      end
    end

    context 'for a file_set' do
      let(:pcdm_object) { fileset2 }
      let(:fileset2_resource) { resource }

      before do
        work1.members = [work3, fileset1, fileset2]
        work3.members = [fileset2, work4]
        work1.save!
        work3.save!
      end

      it 'returns only parent works as Valkyrie resources' do
        parent_works = custom_query_service.find_parent_works(resource: fileset2_resource)
        expect(parent_works.map(&:id)).to match_valkyrie_ids_with_active_fedora_ids([work1.id, work3.id])
      end
    end
  end

  describe '#find_parent_work_ids' do
    context 'for a work' do
      let(:pcdm_object) { work3 }
      let(:work3_resource) { resource }

      before do
        collection1.members = [work3, work4]
        collection1.save!
        work1.members = [work3, fileset1, fileset2]
        work2.members = [work3, work4]
        work1.save!
        work2.save!
      end

      it 'returns Valkyrie ids for parent works only' do
        parent_work_ids = custom_query_service.find_parent_work_ids(resource: work3_resource)
        expect(parent_work_ids).to match_valkyrie_ids_with_active_fedora_ids([work2.id, work1.id])
      end
    end

    context 'for a fileset' do
      let(:pcdm_object) { fileset2 }
      let(:fileset2_resource) { resource }

      before do
        work1.members = [work3, fileset1, fileset2]
        work3.members = [fileset2, work4]
        work1.save!
        work3.save!
      end

      it 'returns Valkyrie ids for parent works only' do
        parent_work_ids = custom_query_service.find_parent_work_ids(resource: fileset2_resource)
        expect(parent_work_ids).to match_valkyrie_ids_with_active_fedora_ids([work1.id, work3.id])
      end
    end
  end
end
