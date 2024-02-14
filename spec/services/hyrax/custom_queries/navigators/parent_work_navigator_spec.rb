# frozen_string_literal: true
RSpec.describe Hyrax::CustomQueries::Navigators::ParentWorkNavigator, valkyrie_adapter: :test_adapter, clean_repo: true do
  let!(:parent_work) { FactoryBot.valkyrie_create(:hyrax_work, id: 'pw1', title: ['Parent Work 1'], member_ids: member_ids) }

  let(:child_work1) { FactoryBot.valkyrie_create(:hyrax_work, id: 'cw1', title: ['Child Work 1']) }
  let(:child_work2) { FactoryBot.valkyrie_create(:hyrax_work, id: 'cw2', title: ['Child Work 2']) }
  let(:fileset1)    { FactoryBot.valkyrie_create(:hyrax_file_set, id: 'fs1', title: ['Child File Set 1']) }
  let(:fileset2)    { FactoryBot.valkyrie_create(:hyrax_file_set, id: 'fs2', title: ['Child File Set 2']) }

  let(:member_ids) do
    [
      child_work1.id,
      child_work2.id,
      fileset1.id,
      fileset2.id
    ]
  end

  let(:custom_query_service) { Hyrax.custom_queries }

  describe '#find_parent_work' do
    context 'on a work' do
      it 'returns one parent work as Valkyrie resources' do
        expect(custom_query_service.find_parent_work(resource: child_work1).id).to eq parent_work.id
      end

      context 'when more than one parent' do
        let!(:work) { FactoryBot.valkyrie_create(:hyrax_work, id: 'pw2', title: ['Parent Work 2'], member_ids: member_ids) }
        let(:child_work3) { FactoryBot.valkyrie_create(:hyrax_work, id: 'cw3', title: ['Child Work 3']) }
        let(:member_ids) { [child_work3.id] }
        it 'logs warning about more than one parent and returns the first parent work as Valkyrie resources' do
          expect(Hyrax.logger).to receive(:warn).with("Work cw3 is in 2 works when it should be in no more than one. Found in pw1, pw2.")
          parent = custom_query_service.find_parent_work(resource: child_work3)
          # There is no guarantee which of the parents will be returned.
          expect([work.id, parent_work.id]).to include parent.id
        end
      end
    end

    context 'on a fileset' do
      it 'returns one parent work as Valkyrie resources' do
        expect(custom_query_service.find_parent_work(resource: fileset1).id).to eq parent_work.id
      end

      context 'when more than one parent' do
        let!(:work) { FactoryBot.valkyrie_create(:hyrax_work, id: 'pw2', title: ['Parent Work 2'], member_ids: member_ids) }
        let(:fileset3) { FactoryBot.valkyrie_create(:hyrax_file_set, id: 'fs3', title: ['Child File Set 3']) }
        let(:member_ids) { [fileset3.id] }
        it 'logs warning about more than one parent and returns the first parent work as Valkyrie resources' do
          expect(Hyrax.logger).to receive(:warn).with("File set fs3 is in 2 works when it should be in no more than one. Found in pw1, pw2.")
          parent = custom_query_service.find_parent_work(resource: fileset3)
          # There is no guarantee which of the parents will be returned.
          expect([work.id, parent_work.id]).to include parent.id
        end
      end
    end

    context 'when no parents' do
      let(:member_ids) { [] }
      it 'returns nil' do
        expect(custom_query_service.find_parent_work(resource: child_work1)).to be_nil
        expect(custom_query_service.find_parent_work(resource: fileset1)).to be_nil
      end
    end
  end

  describe '#find_parent_work_id' do
    context 'on a work' do
      it 'returns the id of one parent work as Valkyrie resources' do
        expect(custom_query_service.find_parent_work_id(resource: child_work1)).to eq parent_work.id
      end
    end

    context 'on a fileset' do
      it 'returns the id of one parent work as Valkyrie resources' do
        expect(custom_query_service.find_parent_work_id(resource: fileset1)).to eq parent_work.id
      end
    end

    context 'when no parents' do
      let(:member_ids) { [] }
      it 'returns nil' do
        expect(custom_query_service.find_parent_work_id(resource: child_work1)).to be_nil
        expect(custom_query_service.find_parent_work_id(resource: fileset1)).to be_nil
      end
    end
  end
end
