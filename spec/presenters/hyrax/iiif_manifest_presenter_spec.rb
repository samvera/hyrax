# frozen_string_literal: true

# rubocop:disable BracesAroundHashParameters maybe a rubocop bug re hash params?
RSpec.describe Hyrax::IiifManifestPresenter do
  subject(:presenter) { described_class.new(work) }
  let(:work) { build(:monograph) }

  describe 'manifest generation' do
    let(:builder_service) { Hyrax::ManifestBuilderService.new }

    it 'generates a IIIF presentation 2.0 manifest' do
      expect(builder_service.manifest_for(presenter: presenter))
        .to include('@context' => 'http://iiif.io/api/presentation/2/context.json')
    end

    context 'with file set and work members' do
      let(:work) { create(:work_with_image_files) }

      it 'generates a manifest with nested content' do
        expect(builder_service.manifest_for(presenter: presenter))
          .to include('@context' => 'http://iiif.io/api/presentation/2/context.json')
      end
    end
  end

  describe '#description' do
    it 'returns a string description of the object' do
      expect(presenter.description).to be_a String
    end
  end

  describe '#file_set_presenters' do
    it 'is empty' do
      expect(presenter.file_set_presenters).to be_empty
    end

    context 'when the work has file set members' do
      let(:work) { build(:monograph, :with_member_works) }

      it 'gives presenters for the file sets'

      context 'and work members' do
        let(:work) { create(:work_with_file_and_work) }

        it 'gives presenters only for the file set members' do
          fs_members = work.members.select(&:file_set?)

          expect(presenter.file_set_presenters)
            .to contain_exactly(*fs_members.map { |member| have_attributes(id: member.id) })
        end
      end
    end
  end

  describe '#manifest_metadata' do
    it 'includes empty metadata' do
      expect(presenter.manifest_metadata)
        .to contain_exactly({ 'label' => 'Title', 'value' => [] },
                            { 'label' => 'Creator', 'value' => [] },
                            { 'label' => 'Rights statement', 'value' => [] })
    end

    context 'with some metadata' do
      let(:work) do
        build(:monograph,
              title: ['Comet in Moominland', 'Mumintrollet på kometjakt'],
              creator: 'Tove Jansson',
              rights_statement: 'free!',
              description: 'A book about moomins')
      end

      it 'includes configured metadata' do
        expect(presenter.manifest_metadata)
          .to contain_exactly({ 'label' => 'Title', 'value' => ['Comet in Moominland', 'Mumintrollet på kometjakt'] },
                              { 'label' => 'Creator', 'value' => ['Tove Jansson'] },
                              { 'label' => 'Rights statement', 'value' => ['free!'] })
      end
    end
  end

  describe '#manifest_url' do
    let(:work) { build(:monograph) }

    it 'gives an empty string for an unpersisted object' do
      expect(presenter.manifest_url).to be_empty
    end

    context 'with a persisted work' do
      let(:work) { valkyrie_create(:monograph) }

      it 'builds a url from the manifest path and work id ' do
        expect(presenter.manifest_url).to include "concern/monographs/#{work.id}/manifest"
      end
    end
  end

  describe '#sequence_rendering' do
    it 'provides an empty sequence rendering' do
      expect(presenter.sequence_rendering).to eq([])
    end

    context 'with file sets' do
      it 'provides a sequence rendering for the file_sets'
    end
  end

  describe '#work_presenters' do
    it 'is empty' do
      expect(presenter.work_presenters).to be_empty
    end

    context 'when the work has member works' do
      let(:work) { build(:monograph, :with_member_works) }

      it 'gives presenters for the members' do
        expect(presenter.work_presenters)
          .to contain_exactly(*work.member_ids.map { |id| have_attributes(id: id) })
      end

      context 'and file set members' do
        let(:work) { create(:work_with_file_and_work) }

        it 'gives presenters only for the work members' do
          work_members = work.members.select(&:work?)

          expect(presenter.work_presenters)
            .to contain_exactly(*work_members.map { |member| have_attributes(id: member.id) })
        end
      end
    end
  end
end
# rubocop:enable BracesAroundHashParameters
