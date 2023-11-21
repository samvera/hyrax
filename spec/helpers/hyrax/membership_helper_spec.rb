# frozen_string_literal: true

RSpec.describe Hyrax::MembershipHelper do
  before { helper.class.include Hyrax::Engine.routes.url_helpers }

  describe '.member_of_collections_json' do
    context 'with a ChangeSet form' do
      let(:resource) { Hyrax::Forms::ResourceForm.for(resource: work) }
      let(:work) { build(:monograph) }

      context 'when it has no collections' do
        it 'gives an empty JSON array' do
          expect(helper.member_of_collections_json(resource)).to eq [].to_json
        end
      end

      context 'when it is a member of a collection' do
        let(:work) { valkyrie_create(:monograph, :as_collection_member) }
        let(:collection) { Hyrax.custom_queries.find_parent_collections(resource: work).first }

        it 'gives collection details' do
          expect(JSON.parse(helper.member_of_collections_json(resource)))
            .to contain_exactly(include('id' => an_instance_of(String),
                                        'label' => collection.title.first,
                                        'path' => an_instance_of(String)))
        end
      end
    end

    context 'with a Valkyrie work' do
      let(:resource) { build(:hyrax_work) }

      context 'when it has no collections' do
        it 'gives an empty JSON array' do
          expect(helper.member_of_collections_json(resource)).to eq [].to_json
        end
      end

      context 'when it is a member of a collection' do
        let(:resource) { valkyrie_create(:hyrax_work, :as_collection_member) }
        let(:collection) { Hyrax.custom_queries.find_parent_collections(resource: resource).first }

        it 'gives collection details' do
          expect(JSON.parse(helper.member_of_collections_json(resource)))
            .to contain_exactly(include('id' => an_instance_of(String),
                                        'label' => collection.title.first,
                                        'path' => an_instance_of(String)))
        end
      end
    end

    context 'with a WorkForm' do
      let(:resource) { double(Hyrax::Forms::WorkForm) }

      it 'calls the form json implementation and returns its result' do
        expect(resource).to receive(:member_of_collections_json).and_return(:FAKE_JSON)
        expect(helper.member_of_collections_json(resource)).to eq :FAKE_JSON
      end
    end
  end

  describe '.work_members_json' do
    context 'with a ChangeSet form' do
      let(:resource) { Hyrax::Forms::ResourceForm.for(resource: work) }
      let(:work) { build(:monograph) }

      context 'when it has no members' do
        it 'gives an empty JSON array' do
          expect(helper.work_members_json(resource)).to eq [].to_json
        end
      end

      context 'when it is a member of a collection' do
        let(:work) { FactoryBot.valkyrie_create(:monograph, :with_member_works) }

        it 'gives member work details' do
          expect(JSON.parse(helper.work_members_json(resource)))
            .to contain_exactly(include('id' => an_instance_of(String),
                                        'label' => nil,
                                        'path' => an_instance_of(String)),
                                include('id' => an_instance_of(String),
                                        'label' => nil,
                                        'path' => an_instance_of(String)))
        end
      end
    end

    context 'with a Valkyrie work' do
      let(:resource) { build(:monograph) }

      context 'when it has no members' do
        it 'gives an empty JSON array' do
          expect(helper.work_members_json(resource)).to eq [].to_json
        end
      end

      context 'when it has work members' do
        let(:resource) { FactoryBot.valkyrie_create(:monograph, :with_member_works) }

        it 'gives member work details' do
          expect(JSON.parse(helper.work_members_json(resource)))
            .to contain_exactly(include('id' => an_instance_of(String),
                                        'label' => nil,
                                        'path' => an_instance_of(String)),
                                include('id' => an_instance_of(String),
                                        'label' => nil,
                                        'path' => an_instance_of(String)))
        end
      end
    end

    context 'with a WorkForm' do
      let(:resource) { double(Hyrax::Forms::WorkForm) }

      it 'calls the form json implementation and returns its result' do
        expect(resource).to receive(:work_members_json).and_return(:FAKE_JSON)
        expect(helper.work_members_json(resource)).to eq :FAKE_JSON
      end
    end
  end
end
