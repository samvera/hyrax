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
        .not_to change { Hyrax.query_service.find_by(id: work.id).member_ids }
        .from be_empty
    end

    it 'does not publish events' do
      expect(listener.object_deposited).to be_empty
      expect(listener.file_set_attached).to be_empty
    end

    context 'after adding files' do
      before { service.add(files: uploads) }

      it 'assigns FileSet ids synchronously' do
        expect { service.attach }
          .to change { Hyrax.query_service.find_by(id: work.id).member_ids }
          .to contain_exactly(an_instance_of(Valkyrie::ID),
                              an_instance_of(Valkyrie::ID),
                              an_instance_of(Valkyrie::ID))
      end

      it 'creates persisted filesets' do
        service.attach
        expect(service.work).to have_file_set_members(be_persisted, be_persisted, be_persisted)
      end

      it 'creates filesets with metadata' do
        service.attach
        expect(service.work)
          .to have_file_set_members(have_attributes(title: ['image.jp2'], depositor: an_instance_of(String), visibility: 'open'),
                                    have_attributes(title: ['image.jp2'], depositor: an_instance_of(String), visibility: 'open'),
                                    have_attributes(title: ['image.jp2'], depositor: an_instance_of(String), visibility: 'open'))
      end

      it 'propagates work permissions to file_sets' do
        service.attach
        expect(service.work)
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
            expect(service.work).to have_file_set_members(have_attributes(alternate_ids: ['fs-1']),
                                                          have_attributes(alternate_ids: ['fs-2']),
                                                          have_attributes(alternate_ids: ['fs-3']))
          end
        end

        context 'that arrive as ActionController::Parameters' do
          let(:file_set_params) do
            [
              ActionController::Parameters.new(alternate_ids: ['fs-1']).permit!,
              ActionController::Parameters.new(alternate_ids: ['fs-2']).permit!,
              ActionController::Parameters.new(alternate_ids: ['fs-3']).permit!
            ]
          end

          it 'assigns the params to the FileSets' do
            service.add(files: uploads, file_set_params: file_set_params)
            service.attach
            expect(service.work).to have_file_set_members(have_attributes(alternate_ids: ['fs-1']),
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
            actual_file_sets = Hyrax.custom_queries.find_child_file_sets(resource: service.work)
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
          expect { service.attach }
            .to change { Hyrax.query_service.find_members(resource: Hyrax.query_service.find_by(id: work.id)) }
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
        expect(service.work).to have_file_set_members(have_attributes(id: first_id),
                                                      have_attributes(id: second_id),
                                                      be_persisted,
                                                      be_persisted,
                                                      be_persisted)
      end
    end

    context 'when another handler saved the work after this copy was read' do
      let(:first_upload) { FactoryBot.create(:uploaded_file) }
      let(:second_upload) { FactoryBot.create(:uploaded_file) }

      it 'keeps the file sets both handlers attached' do
        first_copy = work.dup
        second_copy = work.dup
        described_class.new(work: first_copy).add(files: [first_upload]).attach
        described_class.new(work: second_copy).add(files: [second_upload]).attach

        expect(Hyrax.query_service.find_by(id: work.id).member_ids.map(&:to_s))
          .to contain_exactly(first_upload.reload.file_set_uri, second_upload.reload.file_set_uri)
      end
    end

    context 'when an earlier attempt created the file set without attaching it' do
      let(:upload) { FactoryBot.create(:uploaded_file) }
      let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }

      before { upload.add_file_set!(file_set) }

      it 'attaches the existing file set' do
        service.add(files: [upload]).attach

        expect(Hyrax.query_service.find_by(id: work.id).member_ids).to contain_exactly(file_set.id)
      end
    end

    context "when the upload's file set is already in another work" do
      let(:upload) { FactoryBot.create(:uploaded_file) }
      let(:other_work) { FactoryBot.valkyrie_create(:hyrax_work) }
      let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set, :in_work, work: other_work) }

      before { upload.add_file_set!(file_set) }

      it 'leaves the file set in the other work with its own permissions' do
        permissions = -> { Hyrax::AccessControlList.new(resource: file_set).permissions.map { |p| [p.mode, p.agent] } }

        expect { service.add(files: [upload]).attach }.not_to change(&permissions)
        expect(Hyrax.query_service.find_by(id: work.id).member_ids).to be_empty
      end
    end

    context "when the upload's file set was deleted" do
      let(:upload) { FactoryBot.create(:uploaded_file) }
      let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }

      before do
        upload.add_file_set!(file_set)
        Hyrax.persister.delete(resource: file_set)
      end

      it 'skips the upload' do
        service.add(files: [upload]).attach

        expect(Hyrax.query_service.find_by(id: work.id).member_ids).to be_empty
      end
    end

    context "when the upload's file set was attached through ActiveFedora" do
      let(:upload) { FactoryBot.create(:uploaded_file, file_set_uri: 'http://example.com/file_set') }

      before { allow(Hyrax.query_service).to receive(:find_by).and_call_original }

      it 'skips the upload without looking the URI up as an id' do
        service.add(files: [upload]).attach

        expect(Hyrax.query_service).not_to have_received(:find_by).with(id: upload.file_set_uri)
        expect(Hyrax.query_service.find_by(id: work.id).member_ids).to be_empty
      end
    end

    context 'when another handler attached the file set after this one found it unattached' do
      let(:upload) { FactoryBot.create(:uploaded_file) }
      let(:copy_without_member) { work.dup }

      before do
        copy_without_member
        service.add(files: [upload]).attach
        allow(Hyrax.custom_queries).to receive(:find_parent_work).and_call_original
        allow(Hyrax.custom_queries).to receive(:find_parent_work)
          .with(resource: have_attributes(id: upload.reload.file_set_uri)).and_return(nil)
      end

      it 'does not attach the file set twice' do
        described_class.new(work: copy_without_member).add(files: [upload]).attach

        expect(Hyrax.query_service.find_by(id: work.id).member_ids.map(&:to_s)).to contain_exactly(upload.file_set_uri)
      end

      it 'does not publish file.set.attached for it again' do
        expect { described_class.new(work: copy_without_member).add(files: [upload]).attach }
          .not_to change { listener.file_set_attached.count }
      end
    end

    context 'when a handler for another work reuses the same file set at the same time' do
      let(:upload) { FactoryBot.create(:uploaded_file) }
      let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }
      let(:other_work) { FactoryBot.valkyrie_create(:hyrax_work) }
      before do
        upload.add_file_set!(file_set)
        allow(Hyrax.config).to receive(:lock_retry_count).and_return(0)
        other_handler_ran = false
        allow(Hyrax.custom_queries).to receive(:find_parent_work).and_wrap_original do |original, resource:|
          parent = original.call(resource: resource)
          unless other_handler_ran || resource.id != file_set.id
            other_handler_ran = true
            begin
              described_class.new(work: other_work).add(files: [upload]).attach
            rescue Hyrax::LockManager::UnableToAcquireLockError
              nil
            end
          end
          parent
        end
      end

      it 'attaches the file set to only one work' do
        service.add(files: [upload]).attach

        members = [work, other_work].map { |w| Hyrax.query_service.find_by(id: w.id).member_ids }
        expect(members.flatten).to contain_exactly(file_set.id)
      end
    end
  end
end
