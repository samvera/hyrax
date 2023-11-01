# frozen_string_literal: true
RSpec.describe Hyrax::Dashboard::NestedCollectionsSearchBuilder do
  let(:scope) { double(current_ability: ability, blacklight_config: CatalogController.blacklight_config, search_state_class: nil) }
  let(:access) { :read }
  let(:user) { create(:user) }
  let(:ability) { ::Ability.new(user) }
  let(:test_nest_direction) { :as_parent }

  (Hyrax.config.disable_wings ? [true] : [false, true]).each do |test_valkyrie|
    context "when test_valkyrie is #{test_valkyrie}" do
      let(:builder) do
        described_class.new(scope: scope, access: access, collection: collection, nest_direction: test_nest_direction)
      end
      let(:collection_id) { collection.id.to_s }

      let(:af_collection) do
        FactoryBot.create(:collection_lw,
                          id: af_collection_id,
                          collection_type_gid: 'gid/abc')
      end
      let(:af_collection_id) { 'Collection_123' }

      let(:val_collection) do
        FactoryBot.valkyrie_create(:hyrax_collection,
                                   collection_type_gid: 'gid/abc')
      end

      let(:collection) { test_valkyrie ? val_collection : af_collection }

      describe '#query' do
        subject { builder.query }

        it { is_expected.to be_a(Hash) }
      end

      describe '#default_processor_chain' do
        subject { builder.default_processor_chain }

        it { is_expected.to include(:with_pagination) }
        it { is_expected.to include(:show_only_other_collections_of_the_same_collection_type) }
      end

      describe '#show_only_other_collections_of_the_same_collection_type' do
        let(:solr_params) { {} }

        subject { builder.show_only_other_collections_of_the_same_collection_type(solr_params) }

        context 'when nesting :as_parent' do
          it 'will exclude the given collection, its parents, and direct children' do
            subject
            expect(solr_params.fetch(:fq)).to contain_exactly(
              "_query_:\"{!field f=collection_type_gid_ssim}#{collection.collection_type_gid}\"",
              "-{!graph to=id from=member_of_collection_ids_ssim}id:#{collection.id}",
              "-{!graph from=id to=member_of_collection_ids_ssim maxDepth=1}id:#{collection.id}"
            )
          end
        end

        context 'when nesting :as_child' do
          let(:test_nest_direction) { :as_child }

          it 'will exclude the given collection, its children, and direct parents' do
            subject
            expect(solr_params.fetch(:fq)).to contain_exactly(
              "_query_:\"{!field f=collection_type_gid_ssim}#{collection.collection_type_gid}\"",
              "-{!graph to=id from=member_of_collection_ids_ssim maxDepth=1}id:#{collection.id}",
              "-{!graph from=id to=member_of_collection_ids_ssim}id:#{collection.id}"
            )
          end
        end
      end

      describe '#gated_discovery_filters' do
        subject { builder.gated_discovery_filters(access, ability) }

        before { collection }

        context 'when access is :deposit' do
          let(:access) { "deposit" }

          let(:af_collection) { create(:collection_lw, with_permission_template: af_attributes) }

          let(:val_collection) do
            FactoryBot.valkyrie_create(:hyrax_collection,
                                       with_permission_template: true,
                                       access_grants: val_grants)
          end

          context 'and user has access' do
            let(:af_attributes) { { deposit_users: [user.user_key] } }
            let(:val_grants) do
              [
                {
                  agent_type: Hyrax::PermissionTemplateAccess::USER,
                  agent_id: user.user_key,
                  access: Hyrax::PermissionTemplateAccess::DEPOSIT
                }
              ]
            end

            it { is_expected.to eq ["{!terms f=id}#{collection.id}"] }
          end

          context 'and group has access' do
            let(:af_attributes) { { deposit_groups: ['registered'] } }
            let(:val_grants) do
              [
                {
                  agent_type: Hyrax::PermissionTemplateAccess::GROUP,
                  agent_id: 'registered',
                  access: Hyrax::PermissionTemplateAccess::DEPOSIT
                }
              ]
            end

            it { is_expected.to eq ["{!terms f=id}#{collection.id}"] }
          end

          context "and user has no access" do
            let(:af_attributes) { true }
            let(:val_collection) do
              FactoryBot.valkyrie_create(:hyrax_collection,
                                         with_permission_template: true)
            end

            it { is_expected.to eq ["{!terms f=id}"] }
          end
        end
      end
    end
  end
end
