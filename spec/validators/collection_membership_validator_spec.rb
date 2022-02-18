# frozen_string_literal: true
RSpec.describe Hyrax::CollectionMembershipValidator, :clean_repo do
  describe '#validate' do
    subject(:validator) { described_class.new }

    context 'when record is a work form changeset' do
      let(:form) { Hyrax::Forms::ResourceForm.new(work) }
      let(:work) { FactoryBot.build(:hyrax_work) }
      let(:mem_of_cols_attrs) { {} }

      before { allow(form).to receive(:member_of_collections_attributes).and_return(mem_of_cols_attrs) }

      context 'and there are no changes to collections' do
        let(:mem_of_cols_attrs) { {} }
        it 'validates and leaves member_of_collection_ids empty' do
          validator.validate(form)

          expect(form.errors).to be_blank
          expect(form.member_of_collection_ids).to be_empty
        end

        context 'when it is already in a collection' do
          let(:work) { FactoryBot.build(:hyrax_work, :as_collection_member) }
          let(:col_id) { work.member_of_collection_ids.first.id }

          it 'validates and leaves member_of_collection_ids unchanged' do
            validator.validate(form)

            expect(form.errors).to be_blank
            expect(form.member_of_collection_ids).to contain_exactly(col_id)
          end
        end
      end

      context 'and work is added to collections' do
        let(:col1) { FactoryBot.valkyrie_create(:hyrax_collection) }
        let(:col2) { FactoryBot.valkyrie_create(:hyrax_collection) }
        let(:mem_of_cols_attrs) do
          { "0" => { "id" => col1.id.to_s, "_destroy" => "false" },
            "1" => { "id" => col2.id.to_s, "_destroy" => "false" } }
        end

        it 'validates and sets member_of_collection_ids to new collections' do
          validator.validate(form)

          expect(form.errors).to be_blank
          expect(form.member_of_collection_ids).to contain_exactly(col1.id, col2.id)
        end

        context 'when it is already in a collection' do
          let(:work) { FactoryBot.build(:hyrax_work, :as_collection_member) }
          let(:col_id) { work.member_of_collection_ids.first.id }

          it 'validates and appends new collections to member_of_collection_ids' do
            validator.validate(form)

            expect(form.errors).to be_blank
            expect(form.member_of_collection_ids).to contain_exactly(col_id, col1.id, col2.id)
          end
        end

        context 'and collection type does not allow multiple membership' do
          let(:single_mem_col_type) { FactoryBot.create(:collection_type, allow_multiple_membership: false) }

          context 'and work is not in another collection posing a conflict' do
            let(:work) { FactoryBot.build(:hyrax_work, :as_collection_member) }
            let(:col_id) { work.member_of_collection_ids.first.id }
            let(:sm_col) { FactoryBot.valkyrie_create(:hyrax_collection, collection_type_gid: single_mem_col_type.to_global_id) }
            let(:mem_of_cols_attrs) do
              { "0" => { "id" => sm_col.id.to_s, "_destroy" => "false" } }
            end

            it 'validates and appends new collections to member_of_collection_ids' do
              validator.validate(form)

              expect(form.errors).to be_blank
              expect(form.member_of_collection_ids).to contain_exactly(col_id, sm_col.id)
            end
          end

          context 'and work is in another collection posing a conflict' do
            let(:work) { FactoryBot.build(:hyrax_work, member_of_collection_ids: [sm_col1.id]) }
            let(:sm_col1) { FactoryBot.valkyrie_create(:hyrax_collection, collection_type_gid: single_mem_col_type.to_global_id) }
            let(:sm_col2) { FactoryBot.valkyrie_create(:hyrax_collection, collection_type_gid: single_mem_col_type.to_global_id) }
            let(:mem_of_cols_attrs) do
              { "0" => { "id" => sm_col2.id.to_s, "_destroy" => "false" } }
            end
            # before { work.member_of_collection_ids += [sm_col1.id] }

            it 'fails validating and sets errors' do
              validator.validate(form)

              expect(form.errors).not_to be_blank
              expect(form.member_of_collection_ids).to contain_exactly(sm_col1.id)
            end
          end
        end
      end

      context 'and work is removed from one collection' do
        let(:work) { FactoryBot.build(:hyrax_work, :as_collection_member) }
        let(:col_id) { work.member_of_collection_ids.first.id }
        let(:mem_of_cols_attrs) do
          { "0" => { "id" => col_id, "_destroy" => "true" } }
        end

        it 'validates and leaves member_of_collection_ids empty' do
          validator.validate(form)

          expect(form.errors).to be_blank
          expect(form.member_of_collection_ids).to be_empty
        end

        context 'when it was in multiple collections' do
          let(:work) { FactoryBot.build(:hyrax_work, :as_member_of_multiple_collections) }
          let(:col_ids) { work.member_of_collection_ids }
          let(:remove_col_id) { col_ids.first }
          let(:keep_col_ids) { col_ids - [remove_col_id] }
          let(:mem_of_cols_attrs) do
            { "0" => { "id" => remove_col_id, "_destroy" => "true" } }
          end

          it 'validates and leaves member_of_collection_ids unchanged' do
            validator.validate(form)

            expect(form.errors).to be_blank
            expect(form.member_of_collection_ids).to contain_exactly(*keep_col_ids)
          end
        end
      end
    end

    context 'when record is a collection form changeset' do
      pending "add tests for validating adding collections-to-collections"
    end
  end
end
