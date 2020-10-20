# frozen_string_literal: true

require 'spec_helper'
require 'hyrax/specs/shared_specs/change_set'

RSpec.describe Hyrax::ChangeSet do
  subject(:change_set) { described_class.for(resource) }
  let(:resource)       { build(:hyrax_work) }
  let(:titles)         { ['comet in moominland', 'finn family moomintroll'] }

  it_behaves_like 'a Hyrax::ChangeSet'

  describe 'properties' do
    it 'changes when changed' do
      expect { change_set.title = titles }
        .to change { change_set.changed? }
        .from(false)
        .to(true)
    end

    it 'sets changeset attributes' do
      expect { change_set.title = titles }
        .to change { change_set.title }
        .to contain_exactly(*titles)
    end

    it 'does not expose reserved attributes' do
      expect { change_set.id = 'fake id' }.to raise_error NoMethodError
    end

    it 'does not list reserved attributes as fields' do
      expect(change_set.class.fields)
        .not_to include(*resource.class.reserved_attributes)
    end
  end

  describe '#sync' do
    it 'applies changeset attributes' do
      change_set.title = titles

      expect { change_set.sync }
        .to change { resource.title }
        .to contain_exactly(*titles)
    end

    it 'can save resources after sync' do
      change_set.title = titles
      change_set.sync

      id = Hyrax.persister.save(resource: resource).id

      expect(Hyrax.query_service.find_by(id: id))
        .to have_attributes(title: contain_exactly(*titles))
    end
  end

  describe ".for" do
    context 'when custom change set does not exist' do
      it 'returns an instance of described_class' do
        expect(subject).to be_kind_of described_class
      end
    end

    context 'when custom change set does exist' do
      let(:resource) { Hyrax::Test::BookResource.new }

      it 'returns an instance of custom change set' do
        expect(subject).to be_kind_of Hyrax::Test::BookResourceChangeSet
      end

      context 'and value for custom validation is correct' do
        let(:resource) do
          book = Hyrax::Test::BookResource.new
          book.isbn = '123-4-56-789123-0'
          book
        end
        it 'passes validation' do
          # NOTE isbn has validation presence: true
          expect(subject.valid?).to eq true
        end
      end

      context 'and value for custom validation is incorrect' do
        it 'passes validation' do
          # NOTE isbn has validation presence: true
          expect(subject.valid?).to eq false
        end
      end
    end
  end
end
