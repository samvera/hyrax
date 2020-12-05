# frozen_string_literal: true
require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::WorkUploadsHandler do
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
