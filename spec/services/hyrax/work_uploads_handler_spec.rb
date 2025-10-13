# frozen_string_literal: true
require 'hyrax/specs/spy_listener'
require 'hyrax/specs/shared_specs/simple_work'

RSpec.describe Hyrax::WorkUploadsHandler, valkyrie_adapter: :test_adapter do
  subject(:service) { described_class.new(work: work) }

  let(:uploads) { FactoryBot.create_list(:uploaded_file, 3) }
  let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :public) }

  describe '#attach' do
    let(:listener) { Hyrax::Specs::AppendingSpyListener.new }
    before { Hyrax.publisher.subscribe(listener) }
    after  { Hyrax.publisher.unsubscribe(listener) }

    it 'when no files are added returns uneventfully' do
      expect { service.attach }
        .not_to change { work.member_ids }
        .from be_empty
    end

    it 'does not publish events' do
      expect(listener.object_deposited).to be_empty
      expect(listener.file_set_attached).to be_empty
    end
    # we can't use the memory based test_adapter to test asynch,
    context 'when running background jobs', perform_enqueued: [ValkyrieIngestJob], valkyrie_adapter: :wings_adapter do
      before do
        # stub out  characterization to avoid system calls
        characterize = double(run: true)
        allow(Hyrax.config)
          .to receive(:characterization_service)
          .and_return(characterize)
      end

      it 'persists the uploaded files asynchronously' do
        testing_work = work
        work_one = testing_work.dup
        work_two = testing_work.dup
        work_three = testing_work.dup
        thr = Thread.new do
          [
            described_class.new(work: work_one).add(files: [uploads[0]]).attach,
            described_class.new(work: work_two).add(files: [uploads[1]]).attach,
            described_class.new(work: work_three).add(files: [uploads[2]]).attach
          ]
        end
        thr.join
        reloaded_work = Hyrax.query_service.find_by(id: testing_work.id)
        expect(reloaded_work.member_ids.count).to eq(3)
        expect(Hyrax.query_service.find_members(resource: reloaded_work).count).to eq(3)
        expect(Hyrax.query_service.find_members(resource: reloaded_work))
          .to contain_exactly(have_attached_files,
                              have_attached_files,
                              have_attached_files)
      end
    end

    context 'after adding files' do
      before { service.add(files: uploads) }

      it 'assigns FileSet ids synchronously' do
        expect { service.attach }
          .to change { work.member_ids }
          .to contain_exactly(an_instance_of(Valkyrie::ID),
                              an_instance_of(Valkyrie::ID),
                              an_instance_of(Valkyrie::ID))
      end

      it 'creates persisted filesets' do
        service.attach
        expect(work).to have_file_set_members(be_persisted, be_persisted, be_persisted)
      end

      it 'creates filesets with metadata' do
        service.attach
        expect(work)
          .to have_file_set_members(have_attributes(title: ['image.jp2'], depositor: an_instance_of(String), visibility: 'open'),
                                    have_attributes(title: ['image.jp2'], depositor: an_instance_of(String), visibility: 'open'),
                                    have_attributes(title: ['image.jp2'], depositor: an_instance_of(String), visibility: 'open'))
      end

      it 'propagates work permissions to file_sets' do
        service.attach
        expect(work)
          .to have_file_set_members(be_a_resource_with_permissions(have_attributes(mode: :read, agent: 'group/public')),
                                    be_a_resource_with_permissions(have_attributes(mode: :read, agent: 'group/public')),
                                    be_a_resource_with_permissions(have_attributes(mode: :read, agent: 'group/public')))
      end

      it 'publishes object.created events for file_sets' do
        expect { service.attach }
          .to change { listener.object_deposited }
          .to contain_exactly(have_attributes(payload: include(object: be_file_set)),
                              have_attributes(payload: include(object: be_file_set)),
                              have_attributes(payload: include(object: be_file_set)))
      end

      it 'publishes file.set.attached events' do
        expect { service.attach }
          .to change { listener.file_set_attached }
          .to contain_exactly(have_attributes(payload: include(file_set: be_file_set)),
                              have_attributes(payload: include(file_set: be_file_set)),
                              have_attributes(payload: include(file_set: be_file_set)))
      end

      it 'publishes object.metadata.updated event for work' do
        expect { service.attach }
          .to change { listener.object_metadata_updated }
          .to contain_exactly(have_attributes(payload: include(object: be_work)))
      end

      context 'with file_set_params' do
        context 'that are valid' do
          let(:file_set_params) do
            [
              { alternate_ids: ['fs-1'] },
              { alternate_ids: ['fs-2'] },
              { alternate_ids: ['fs-3'] }
            ]
          end

          it 'assigns the file_set_params to the FileSets' do
            service.add(files: uploads, file_set_params: file_set_params)
            service.attach
            expect(work).to have_file_set_members(have_attributes(alternate_ids: ['fs-1']),
                                                  have_attributes(alternate_ids: ['fs-2']),
                                                  have_attributes(alternate_ids: ['fs-3']))
          end
        end

        context 'that are not in the schema' do
          let(:file_set_params) do
            [
              { liverwurst: ['not applied 1'] },
              { liverwurst: ['not applied 2'] },
              { liverwurst: ['not applied 3'] }
            ]
          end

          it 'does not assign the invalid file_set_params to the FileSets' do
            service.add(files: uploads, file_set_params: file_set_params)
            service.attach
            actual_file_sets = Hyrax.custom_queries.find_child_file_sets(resource: work)
            expect(actual_file_sets.size).to eq(3)
            actual_file_sets.each do |fs|
              expect(fs).not_to have_attribute(:liverwurst)
            end
          end
        end
      end

      # we can't use the memory based test_adapter to test asynch,
      context 'when running background jobs', perform_enqueued: [ValkyrieIngestJob], valkyrie_adapter: :wings_adapter do
        before do
          # stub out  characterization to avoid system calls
          characterize = double(run: true)
          allow(Hyrax.config)
            .to receive(:characterization_service)
            .and_return(characterize)
        end

        it 'persists the uploaded files asynchronously' do
          service.attach
          reloaded_work = Hyrax.query_service.find_by(id: work.id)
          expect(Hyrax.query_service.find_members(resource: reloaded_work))
            .to contain_exactly(have_attached_files,
                                have_attached_files,
                                have_attached_files)
        end
      end
    end

    context 'with existing file_sets' do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :public, :with_member_file_sets) }

      it 'appends the new file sets' do
        first_id, second_id = work.member_ids

        service.add(files: uploads).attach
        expect(work).to have_file_set_members(have_attributes(id: first_id),
                                              have_attributes(id: second_id),
                                              be_persisted,
                                              be_persisted,
                                              be_persisted)
      end
    end
  end
end
