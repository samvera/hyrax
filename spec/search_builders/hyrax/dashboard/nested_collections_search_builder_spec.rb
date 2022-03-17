# frozen_string_literal: true
RSpec.describe Hyrax::Dashboard::NestedCollectionsSearchBuilder do
  let(:scope) { double(current_ability: ability, blacklight_config: CatalogController.blacklight_config) }
  let(:access) { :read }
  let(:user) { create(:user) }
  let(:ability) { ::Ability.new(user) }
  let(:test_nest_direction) { :as_parent }

  [false, true].each do |test_valkyrie|
    context "when test_valkyrie is #{test_valkyrie}" do
      let(:builder) do
        described_class.new(scope: scope, access: access, collection: collection,
                            nesting_attributes: nesting_attributes, nest_direction: test_nest_direction)
      end
      let(:nesting_attributes) do
        double(parents: ['Parent_1', 'Parent_2'],
               pathnames: ["Parent_1/#{collection_id}", "Parent_2/#{collection_id}"],
               ancestors: ['Parent_1', 'Parent_2'],
               depth: 2)
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
          let(:test_nest_direction) { :as_parent }

          it 'will exclude the given collection and its parents' do
            subject
            expect(solr_params.fetch(:fq)).to contain_exactly(
              "-{!terms f=id}#{collection_id},#{nesting_attributes.parents.first},#{nesting_attributes.parents.last}",
              "_query_:\"{!field f=collection_type_gid_ssim}#{collection.collection_type_gid}\"",
              "-_query_:\"{!lucene df=nesting_collection__pathnames_ssim}*#{collection_id}*\""
            )
          end
        end

        context 'when nesting :as_child' do
          let(:test_nest_direction) { :as_child }

          it 'will build the search for valid children' do
            subject
            # rubocop:disable Layout/LineLength
            expect(solr_params.fetch(:fq)).to contain_exactly(
              "-{!terms f=id}#{collection_id}",
              "_query_:\"{!field f=collection_type_gid_ssim}#{collection.collection_type_gid}\"",
              "-_query_:\"{!lucene q.op=OR df=nesting_collection__pathnames_ssim}#{nesting_attributes.pathnames.first} #{nesting_attributes.pathnames.last} #{nesting_attributes.ancestors.first} #{nesting_attributes.ancestors.last}\"",
              "-_query_:\"{!field f=nesting_collection__parent_ids_ssim}#{collection_id}\""
            )
            # rubocop:enable Layout/LineLength
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
