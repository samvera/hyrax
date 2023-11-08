# frozen_string_literal: true

RSpec.describe Hyrax::CollectionMembershipValidator do
  subject(:validator) { described_class.new }
  let(:work) { FactoryBot.build(:hyrax_work, :as_collection_member) }
  let(:form) { Hyrax::Forms::ResourceForm(Monograph).new(resource: work) }

  describe '#validate' do
    it 'is valid' do
      expect { validator.validate(form) }
        .not_to change { form.errors }
        .from be_empty
    end

    it 'does not change existing collections' do
      expect { validator.validate(form) }
        .not_to change { form.member_of_collection_ids }
    end

    context 'when record is a work form changeset' do
      let(:form) { Hyrax::Forms::ResourceForm.for(resource: work) }
      let(:work) { FactoryBot.build(:hyrax_work) }
      let(:mem_of_cols_attrs) { {} }

      before do
        form.member_of_collections_attributes = mem_of_cols_attrs
      end

      context 'and there are no collections' do
        let(:mem_of_cols_attrs) { nil }

        it 'is valid' do
          validator.validate(form)

          expect(form.errors).to be_blank
        end
      end

      context 'and work is added to collections' do
        let(:col1) { FactoryBot.valkyrie_create(:hyrax_collection) }
        let(:col2) { FactoryBot.valkyrie_create(:hyrax_collection) }

        let(:mem_of_cols_attrs) do
          { "0" => { "id" => col1.id.to_s, "_destroy" => "false" },
            "1" => { "id" => col2.id.to_s, "_destroy" => "false" } }
        end

        it 'is valid' do
          validator.validate(form)

          expect(form.errors).to be_blank
        end

        context 'when it is already in a collection' do
          let(:work) { FactoryBot.build(:hyrax_work, :as_collection_member) }
          let(:col_id) { work.member_of_collection_ids.first.id }

          it 'is valid' do
            validator.validate(form)

            expect(form.errors).to be_blank
          end
        end

        context 'and collection type does not allow multiple membership' do
          let(:single_mem_col_type) { FactoryBot.create(:collection_type, allow_multiple_membership: false) }

          context 'and work is in another collection NOT posing a conflict' do
            let(:work) { FactoryBot.build(:hyrax_work, :as_collection_member) }
            let(:col_id) { work.member_of_collection_ids.first.id }
            let(:sm_col) { FactoryBot.valkyrie_create(:hyrax_collection, collection_type_gid: single_mem_col_type.to_global_id.to_s) }
            let(:mem_of_cols_attrs) do
              { "0" => { "id" => col_id.to_s, "_destroy" => "false" },
                "1" => { "id" => sm_col.id.to_s, "_destroy" => "false" } }
            end

            it 'is valid' do
              validator.validate(form)

              expect(form.errors).to be_blank
            end
          end

          context 'and work is already ni collections with membership restriction conflicts' do
            let(:work) { FactoryBot.build(:hyrax_work, member_of_collection_ids: [sm_col1.id]) }
            let(:sm_col1) { FactoryBot.valkyrie_create(:hyrax_collection, collection_type_gid: single_mem_col_type.to_global_id.to_s) }
            let(:sm_col2) { FactoryBot.valkyrie_create(:hyrax_collection, collection_type_gid: single_mem_col_type.to_global_id.to_s) }

            let(:mem_of_cols_attrs) do
              { "0" => { "id" => sm_col2.id.to_s, "_destroy" => "false" } }
            end

            it 'adds validation errors' do
              validator.validate(form)

              expect(form.errors)
                .to contain_exactly(
                      start_with('Member of collection ids Error: ' \
                                 'You have specified more than one of ' \
                                 'the same single-membership collection type')
                    )
            end
          end

          context 'and work is added to collections with membership restriction conflicts' do
            let(:work) { FactoryBot.build(:hyrax_work) }
            let(:sm_col1) { FactoryBot.valkyrie_create(:hyrax_collection, collection_type_gid: single_mem_col_type.to_global_id.to_s) }
            let(:sm_col2) { FactoryBot.valkyrie_create(:hyrax_collection, collection_type_gid: single_mem_col_type.to_global_id.to_s) }
            let(:mem_of_cols_attrs) do
              { "0" => { "id" => sm_col1.id.to_s, "_destroy" => "false" },
                "1" => { "id" => sm_col2.id.to_s, "_destroy" => "false" } }
            end

            it 'adds validation errors' do
              validator.validate(form)

              expect(form.errors)
                .to contain_exactly(
                      start_with('Member of collection ids Error: ' \
                                 'You have specified more than one of ' \
                                 'the same single-membership collection type')
                    )
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
          it 'validates member_of_collection_ids to empty' do
            validator.validate(form)

            expect(form.errors).to be_blank
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

          it 'is valid rest' do
            validator.validate(form)

            expect(form.errors).to be_blank
          end
        end
      end
    end

    context 'when record is a collection form changeset' do
      let(:form) { Hyrax::Forms::PcdmCollectionForm.new(col) }
      let(:col) { FactoryBot.build(:hyrax_collection) }
      let(:mem_of_cols_attrs) { {} }

      context 'and there are no collections' do
        let(:mem_of_cols_attrs) { {} }

        it 'is valid' do
          validator.validate(form)

          expect(form.errors).to be_blank
        end
      end

      context 'and collection is added to collections' do
        let(:col1) { FactoryBot.valkyrie_create(:hyrax_collection) }
        let(:col2) { FactoryBot.valkyrie_create(:hyrax_collection) }
        let(:mem_of_cols_attrs) do
          { "0" => { "id" => col1.id.to_s, "_destroy" => "false" },
            "1" => { "id" => col2.id.to_s, "_destroy" => "false" } }
        end

        it 'is valid' do
          validator.validate(form)

          expect(form.errors).to be_blank
        end

        context 'when it is already in a collection' do
          let(:col) { FactoryBot.build(:hyrax_collection, :as_collection_member) }
          let(:col_id) { col.member_of_collection_ids.first.id }

          it 'is valid' do
            validator.validate(form)

            expect(form.errors).to be_blank
          end
        end

        context 'and collection type of parent collection does not allow multiple membership' do
          let(:single_mem_col_type) { FactoryBot.create(:collection_type, allow_multiple_membership: false) }

          context 'and collection is in another collection of a different collection type' do
            let(:col) { FactoryBot.build(:hyrax_collection, :as_collection_member) }
            let(:col_id) { col.member_of_collection_ids.first.id }
            let(:sm_col) { FactoryBot.valkyrie_create(:hyrax_collection, collection_type_gid: single_mem_col_type.to_global_id.to_s) }
            let(:mem_of_cols_attrs) do
              { "0" => { "id" => col_id.to_s, "_destroy" => "false" },
                "1" => { "id" => sm_col.id.to_s, "_destroy" => "false" } }
            end

            it 'is valid' do
              validator.validate(form)

              expect(form.errors).to be_blank
            end
          end

          context 'and collection is in another collection of the same single membership type' do
            let(:col) { FactoryBot.build(:hyrax_collection, member_of_collection_ids: [sm_col1.id]) }
            let(:sm_col1) { FactoryBot.valkyrie_create(:hyrax_collection, collection_type_gid: single_mem_col_type.to_global_id.to_s) }
            let(:sm_col2) { FactoryBot.valkyrie_create(:hyrax_collection, collection_type_gid: single_mem_col_type.to_global_id.to_s) }
            let(:mem_of_cols_attrs) do
              { "0" => { "id" => sm_col1.id.to_s, "_destroy" => "false" },
                "1" => { "id" => sm_col2.id.to_s, "_destroy" => "false" } }
            end

            it 'is valid' do
              # @note This passes because collections are always allowed in any other collection
              #   as long as all collections involved support nesting.  As nesting is not validated
              #   by this validator, it is not tested here.
              validator.validate(form)

              expect(form.errors).to be_blank
            end
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
          it 'is valid' do
            validator.validate(form)

            expect(form.errors).to be_blank
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

          it 'is valid' do
            validator.validate(form)

            expect(form.errors).to be_blank
          end
        end
      end
    end
  end
end
