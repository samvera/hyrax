# frozen_string_literal: true
RSpec.describe Hyrax::CollectionMembershipValidator, :clean_repo do
  describe '#validate' do
    subject(:validator) { described_class.new }

    context 'when record is a work form changeset' do
      let(:form) { Hyrax::Forms::ResourceForm.new(work) }
      let(:work) { FactoryBot.build(:hyrax_work) }
      let(:mem_of_cols_attrs) { {} }

      # @note The form sets :member_of_collections_attributes to include
      #   * all collections (already existing and newly added) that will be the set of collections
      #   * any collections that were removed
      # The validator is only checking collections that will be the set of collections.
      before { allow(form).to receive(:member_of_collections_attributes).and_return(mem_of_cols_attrs) }

      context 'and there are no collections' do
        let(:mem_of_cols_attrs) { nil }
        it 'validates and sets member_of_collection_ids to empty' do
          validator.validate(form)

          expect(form.errors).to be_blank
          expect(form.member_of_collection_ids).to be_empty
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

          it 'validates and replaces member_of_collection_ids with new collection set' do
            validator.validate(form)

            expect(form.errors).to be_blank
            expect(form.member_of_collection_ids).to contain_exactly(col1.id, col2.id)
          end
        end

        context 'and collection type does not allow multiple membership' do
          let(:single_mem_col_type) { FactoryBot.create(:collection_type, allow_multiple_membership: false) }

          context 'and work is in another collection NOT posing a conflict' do
            let(:work) { FactoryBot.build(:hyrax_work, :as_collection_member) }
            let(:col_id) { work.member_of_collection_ids.first.id }
            let(:sm_col) { FactoryBot.valkyrie_create(:hyrax_collection, collection_type_gid: single_mem_col_type.to_global_id) }
            let(:mem_of_cols_attrs) do
              { "0" => { "id" => col_id.to_s, "_destroy" => "false" },
                "1" => { "id" => sm_col.id.to_s, "_destroy" => "false" } }
            end

            it 'validates and appends new collections to member_of_collection_ids' do
              validator.validate(form)

              expect(form.errors).to be_blank
              expect(form.member_of_collection_ids).to contain_exactly(col_id, sm_col.id)
            end
          end

          context 'and work is in another collection that IS posing a conflict' do
            let(:work) { FactoryBot.build(:hyrax_work, member_of_collection_ids: [sm_col1.id]) }
            let(:sm_col1) { FactoryBot.valkyrie_create(:hyrax_collection, collection_type_gid: single_mem_col_type.to_global_id) }
            let(:sm_col2) { FactoryBot.valkyrie_create(:hyrax_collection, collection_type_gid: single_mem_col_type.to_global_id) }
            let(:mem_of_cols_attrs) do
              { "0" => { "id" => sm_col1.id.to_s, "_destroy" => "false" },
                "1" => { "id" => sm_col2.id.to_s, "_destroy" => "false" } }
            end

            it 'fails validating and sets errors' do
              validator.validate(form)

              expect(form.errors).not_to be_blank
            end
          end
        end
      end

      context 'and includes removing work from a collection' do
        let(:work) { FactoryBot.build(:hyrax_work, :as_collection_member) }
        let(:col_id) { work.member_of_collection_ids.first.id }
        let(:mem_of_cols_attrs) do
          { "0" => { "id" => col_id, "_destroy" => "true" } }
        end

        context 'when only one collections' do
          it 'validates and sets member_of_collection_ids to empty' do
            validator.validate(form)

            expect(form.errors).to be_blank
            expect(form.member_of_collection_ids).to be_empty
          end
        end

        context 'when it was in multiple collections' do
          let(:work) { FactoryBot.build(:hyrax_work, :as_member_of_multiple_collections) }
          let(:col_ids) { work.member_of_collection_ids }
          let(:remove_col_id) { col_ids.first }
          let(:keep_col_ids) { col_ids - [remove_col_id] }
          let(:mem_of_cols_attrs) do
            { "0" => { "id" => remove_col_id, "_destroy" => "true" },
              "1" => { "id" => keep_col_ids.first, "_destroy" => "false" },
              "2" => { "id" => keep_col_ids.second, "_destroy" => "false" } }
          end

          it 'validates, removing one collection, and leaving the rest' do
            validator.validate(form)

            expect(form.errors).to be_blank
            expect(form.member_of_collection_ids).to contain_exactly(*keep_col_ids)
          end
        end
      end
    end

    context 'when record is a collection form changeset' do
      let(:form) { Hyrax::Forms::PcdmCollectionForm.new(col) }
      let(:col) { FactoryBot.build(:hyrax_collection) }
      let(:mem_of_cols_attrs) { {} }

      # @note Collections do not restrict membership and always pass validation
      before { allow(form).to receive(:member_of_collections_attributes).and_return(mem_of_cols_attrs) }

      context 'and there are no collections' do
        let(:mem_of_cols_attrs) { {} }
        it 'validates and sets member_of_collection_ids to empty' do
          validator.validate(form)

          expect(form.errors).to be_blank
          expect(form.member_of_collection_ids).to be_empty
        end
      end

      context 'and collection is added to collections' do
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
          let(:col) { FactoryBot.build(:hyrax_collection, :as_collection_member) }
          let(:col_id) { col.member_of_collection_ids.first.id }

          it 'validates and replaces member_of_collection_ids with new collection set' do
            validator.validate(form)

            expect(form.errors).to be_blank
            expect(form.member_of_collection_ids).to contain_exactly(col1.id, col2.id)
          end
        end
      end

      context 'and includes removing collection from a collection' do
        let(:col) { FactoryBot.build(:hyrax_collection, :as_collection_member) }
        let(:col_id) { col.member_of_collection_ids.first.id }
        let(:mem_of_cols_attrs) do
          { "0" => { "id" => col_id, "_destroy" => "true" } }
        end

        context 'when only one collections' do
          it 'validates and sets member_of_collection_ids to empty' do
            validator.validate(form)

            expect(form.errors).to be_blank
            expect(form.member_of_collection_ids).to be_empty
          end
        end

        context 'when it was in multiple collections' do
          let(:col) { FactoryBot.build(:hyrax_collection, :as_member_of_multiple_collections) }
          let(:col_ids) { col.member_of_collection_ids }
          let(:remove_col_id) { col_ids.first }
          let(:keep_col_ids) { col_ids - [remove_col_id] }
          let(:mem_of_cols_attrs) do
            { "0" => { "id" => remove_col_id, "_destroy" => "true" },
              "1" => { "id" => keep_col_ids.first, "_destroy" => "false" },
              "2" => { "id" => keep_col_ids.second, "_destroy" => "false" } }
          end

          it 'validates, removing one collection, and leaving the rest' do
            validator.validate(form)

            expect(form.errors).to be_blank
            expect(form.member_of_collection_ids).to contain_exactly(*keep_col_ids)
          end
        end
      end
    end
  end
end
