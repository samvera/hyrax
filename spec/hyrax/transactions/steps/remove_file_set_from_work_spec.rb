# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions/steps/add_to_collections'
require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::Transactions::Steps::RemoveFileSetFromWork do
  subject(:step) { described_class.new }
  let(:file_set) { FactoryBot.build(:hyrax_file_set) }

  describe '#call' do
    it 'is a Failure' do
      expect(step.call(file_set)).to be_failure
    end

    context 'with a user' do
      let(:user) { FactoryBot.create(:user) }

      it 'succeeds' do
        expect(step.call(file_set, user: user)).to be_success
      end

      context 'and with a parent' do
        let(:work) do
          FactoryBot.valkyrie_create(:hyrax_work,
                                     :with_member_file_sets,
                                     :with_representative,
                                     :with_thumbnail)
        end
        let(:file_sets) { Hyrax.query_service.custom_queries.find_child_file_sets(resource: work) }
        let(:file_set) { file_sets.first }
        # let(:file_set) { work.file_sets.to_a.first }
        # let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set, :in_work) }
        let(:listener) { Hyrax::Specs::SpyListener.new }

        before { Hyrax.publisher.subscribe(listener) }
        after  { Hyrax.publisher.unsubscribe(listener) }

        it 'removes the file set from the parent' do
          expect { step.call(file_set, user: user) }
            .to change { Hyrax.query_service.find_parents(resource: file_set).to_a }
            .to be_empty
        end

        describe 'it unlinks the file set from the parent' do
          # before do
          #   expect(step).to receive(:do_it) do |args|
          #     expect(args[0].id).to eq work.id
          #     expect(args[1].id).to eq file_set.id
          #   end.and_call_original
          #   #puts work.class.name
          #   #puts work.methods.sort.join "\n"
          # end

          it 'unlinks' do
            # byebug
            puts "file_set.id=#{file_set.id}"
            puts "work.member_ids=#{work.member_ids}"
            puts "work.thumbnail_id=#{work.thumbnail_id}"
            puts "work.representative_id=#{work.representative_id}"
            expect(work.member_ids.include? file_set.id).to eq true
            expect(work.representative_id).to eq file_set.id
            expect(Hyrax.query_service.find_parents(resource: file_set).is_a? Array).to eq true
            expect(Hyrax.query_service.find_parents(resource: file_set).first).to eq work
            step.call(file_set, user: user)
            reloaded = Hyrax.query_service.find_by(id: work.id)
            expect(work.id).to eq reloaded.id
            puts "file_set.id=#{file_set.id}"
            puts "reloaded.member_ids=#{reloaded.member_ids}"
            puts "reloaded.thumbnail_id=#{reloaded.thumbnail_id}"
            puts "reloaded.representative_id=#{reloaded.representative_id}"
            expect(reloaded.member_ids.include? file_set.id).to eq false
            expect(reloaded.thumbnail_id).not_to eq file_set.id
            expect(reloaded.representative_id).not_to eq file_set.id
            # byebug
            # puts "file_set.id=#{file_set.id}"
            # puts "work.member_ids=#{work.member_ids}"
            # puts "work.thumbnail_id=#{work.thumbnail_id}"
            # puts "work.representative_id=#{work.representative_id}"
            # expect(work.member_ids.include? file_set.id).to eq false
            # expect(work.representative_id).not_to eq file_set.id
          end
        end

        it 'publishes an update of the parent' do
          expect { step.call(file_set, user: user) }
            .to change { listener.object_metadata_updated&.payload }
            .to match object: be_a(Hyrax::Resource), user: user
        end
      end
    end
  end
end
