# frozen_string_literal: true

RSpec.describe Hyrax::WorkUploadsHandler do
  subject(:service) { described_class.new(work: work) }

  let(:uploads) { FactoryBot.create_list(:uploaded_file, 3) }
  let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :public) }

  describe '#attach' do
    it 'when no files are added returns uneventfully' do
      expect { service.attach }
        .not_to change { work.member_ids }
        .from be_empty
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
    end
  end
end
