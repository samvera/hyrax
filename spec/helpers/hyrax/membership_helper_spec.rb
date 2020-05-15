# frozen_string_literal: true

RSpec.describe Hyrax::MembershipHelper do
  before { helper.class.include Hyrax::Engine.routes.url_helpers }

  describe '.member_of_collections_json' do
    context 'with a ChangeSet form' do
      let(:resource) { Hyrax::Forms::ResourceForm.for(work) }
      let(:work) { build(:monograph) }

      context 'when it has no collections' do
        it 'gives an empty JSON array' do
          expect(helper.member_of_collections_json(resource)).to eq [].to_json
        end
      end

      context 'when it is a member of a collection' do
        let(:work) { build(:monograph, :as_collection_member) }

        it 'gives collection details' do
          expect(JSON.parse(helper.member_of_collections_json(resource)))
            .to contain_exactly(include('id' => an_instance_of(String),
                                        'label' => 'The Tove Jansson Collection',
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
        let(:resource) { build(:hyrax_work, :as_collection_member) }

        it 'gives collection details' do
          expect(JSON.parse(helper.member_of_collections_json(resource)))
            .to contain_exactly(include('id' => an_instance_of(String),
                                        'label' => 'The Tove Jansson Collection',
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
end
