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
        expect(builder_service.manifest_for(presenter: presenter)['sequences'].first['canvases'].count)
          .to eq 2 # two image file_set members from the factory
      end

      context 'and an ability' do
        let(:ability) { Ability.new(user) }
        let(:user) { create(:user) }

        before { presenter.ability = ability }

        it 'excludes items the user cannot read' do
          expect(builder_service.manifest_for(presenter: presenter))
            .not_to have_key('sequences')
        end

        it 'includes items with read permissions' do
          readable = FactoryBot.create(:file_set, :image, user: user)
          work.members << readable
          work.save

          expect(builder_service.manifest_for(presenter: presenter)['sequences'].first['canvases'].count)
            .to eq 1 # just the one readable file_set; not the two from the factory
        end
      end
    end
  end

  describe Hyrax::IiifManifestPresenter::DisplayImagePresenter do
    subject(:presenter) { described_class.new(solr_doc) }
    let(:solr_doc) { SolrDocument.new(file_set.to_solr) }
    let(:file_set) { create(:file_set, :image) }

    describe '#display_image' do
      it 'gives a IIIFManifest::DisplayImage' do
        expect(presenter.display_image.to_json)
          .to include 'fcr:versions%2Fversion1/full'
      end

      context 'with non-image file_set' do
        let(:file_set) { create(:file_set) }

        it 'returns nil' do
          expect(presenter.display_image).to be_nil
        end
      end

      context 'when no original file is indexed' do
        let(:solr_doc) do
          index_hash = file_set.to_solr
          index_hash.delete('original_file_id_ssi')

          SolrDocument.new(index_hash)
        end

        it 'can still resolve the image' do
          expect(presenter.display_image.to_json)
            .to include 'fcr:versions%2Fversion1/full'
        end
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
      let(:work) { create(:work_with_image_files) }

      it 'gives presenters for the file sets' do
        expect(presenter.file_set_presenters)
          .to contain_exactly(*work.member_ids.map { |id| have_attributes(id: id) })
      end

      it 'gives DisplayImagePresenters' do
        expect(presenter.file_set_presenters.map(&:display_image))
          .to contain_exactly(an_instance_of(IIIFManifest::DisplayImage),
                              an_instance_of(IIIFManifest::DisplayImage))
      end

      context 'and work members' do
        let(:work) { create(:work_with_file_and_work) }

        it 'gives presenters only for the file set members' do
          fs_members = work.members.select(&:file_set?)

          expect(presenter.file_set_presenters)
            .to contain_exactly(*fs_members.map { |member| have_attributes(id: member.id) })
        end

        context 'and an ability' do
          let(:ability) { Ability.new(user) }
          let(:user) { create(:user) }

          before { presenter.ability = ability }

          it 'is empty when the user cannot read any file sets' do
            expect(presenter.file_set_presenters).to be_empty
          end

          it 'has file sets the user can read' do
            readable = FactoryBot.create(:file_set, :image, user: user)
            work.members << readable
            work.save

            expect(presenter.file_set_presenters)
              .to contain_exactly(have_attributes(id: readable.id))
          end
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

    context 'with file sets in a rendering sequence' do
      let(:work) { create(:work_with_image_files) }

      before do
        work.rendering_ids = work.file_set_ids
        work.save!
      end

      it 'provides a sequence rendering for the file_sets' do
        expect(presenter.sequence_rendering.count).to eq 2
      end
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

  describe '#version' do
    let(:work) { create(:work) }

    it 'returns a string' do
      expect(presenter.version).to be_a String
    end

    context 'when the work is unsaved' do
      let(:work) { build(:monograph) }

      it 'is still a string' do
        expect(presenter.version).to be_a String
      end
    end
  end
end
# rubocop:enable Style/BracesAroundHashParameters
