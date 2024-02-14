# frozen_string_literal: true

RSpec.describe Hyrax::IiifManifestPresenter, :clean_repo do
  subject(:presenter) { described_class.new(work) }
  let(:work) { build(:monograph) }
  let(:file_path) { fixture_path + '/world.png' }
  let(:original_file) { File.open(file_path) }
  let(:uploaded_file) { FactoryBot.create(:uploaded_file, file: original_file) }

  let(:original_file_metadata) do
    valkyrie_create(:hyrax_file_metadata, :original_file, :image, :with_file,
                    original_filename: 'world.png',
                    file_set: file_set,
                    file: uploaded_file)
  end

  let(:second_file_metadata) do
    valkyrie_create(:hyrax_file_metadata, :original_file, :image, :with_file,
                    file_set: second_file_set,
                    file: uploaded_file)
  end

  let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }
  let(:second_file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }

  shared_context 'with assigned ability' do
    let(:ability) { Ability.new(user) }
    let(:user) { create(:user) }

    before { presenter.ability = ability }
  end

  shared_examples 'test for expected method responses' do
    it { is_expected.to respond_to :hostname }
    it { is_expected.to respond_to :ability }
  end

  shared_examples 'tests for image resolution' do
    it 'can still resolve the image' do
      allow_any_instance_of(Hyrax::IiifManifestPresenter::DisplayImagePresenter)
        .to receive(:latest_file_id).and_return('123')

      expect(presenter.display_image.to_json).to include 'images/123/full'
    end
  end

  include_examples 'test for expected method responses'

  describe 'manifest generation' do
    let(:builder_service) { Hyrax::ManifestBuilderService.new }

    it 'generates a IIIF presentation 2.0 manifest' do
      expect(builder_service.manifest_for(presenter: presenter))
        .to include('@context' => 'http://iiif.io/api/presentation/2/context.json')
    end

    context 'with file set and work members' do
      let(:work) { valkyrie_create(:monograph, members: [file_set, second_file_set]) }

      it 'generates a manifest with nested content' do
        original_file_metadata
        second_file_metadata

        expect(builder_service.manifest_for(presenter: presenter)['sequences'].first['canvases'].count)
          .to eq 2 # two image file_set members from the factory
      end

      context 'and an ability' do
        include_context 'with assigned ability'

        it 'excludes items the user cannot read' do
          expect(builder_service.manifest_for(presenter: presenter)).not_to have_key('sequences')
        end

        context 'with readable items' do
          let(:file_set) do
            FactoryBot.valkyrie_create(:hyrax_file_set, read_users: [user])
          end

          it 'includes items with read permissions' do
            original_file_metadata
            second_file_metadata

            expect(builder_service.manifest_for(presenter: presenter)['sequences'].first['canvases'].count)
              .to eq 1 # just the one readable file_set; not the two from the factory
          end
        end
      end
    end
  end

  describe Hyrax::IiifManifestPresenter::DisplayImagePresenter do
    subject(:presenter) { described_class.new(solr_doc) }
    let(:solr_doc) { SolrDocument.new(Hyrax::ValkyrieIndexer.for(resource: file_set).to_solr) }

    before do
      original_file_metadata
    end

    shared_examples 'test for expected method responses'

    describe '#display_image' do
      shared_examples 'tests for image resolution'

      context 'with non-image file_set' do
        let(:original_file_metadata) { }

        it('returns nil') { expect(presenter.display_image).to be_nil }
      end

      context 'when no original file is indexed' do
        let(:solr_doc) do
          index_hash = Hyrax::ValkyrieIndexer.for(resource: file_set).to_solr
          index_hash.delete('original_file_id_ssi')

          SolrDocument.new(index_hash)
        end

        shared_examples 'tests for image resolution'
      end
    end
  end

  describe '#description' do
    it('returns a string description of the object') { expect(presenter.description).to be_a String }
  end

  describe '#file_set_presenters' do
    it('is empty') { expect(presenter.file_set_presenters).to be_empty }

    context 'when the work has file set members' do
      let(:work) { valkyrie_create(:monograph, members: [file_set, second_file_set]) }

      before do
        original_file_metadata
        second_file_metadata
      end

      it 'gives DisplayImagePresenters for the file sets' do
        expect(presenter.file_set_presenters)
          .to contain_exactly(*work.member_ids.map { |id| have_attributes(id: id) })
        expect(presenter.file_set_presenters.map(&:display_image))
          .to contain_exactly(an_instance_of(IIIFManifest::DisplayImage),
                              an_instance_of(IIIFManifest::DisplayImage))
      end

      context 'and work members' do
        let(:work) { valkyrie_create(:monograph, members: [valkyrie_create(:monograph), file_set, second_file_set]) }

        it 'gives presenters only for the file set members' do
          fs_members = work.member_ids.map { |id| Hyrax.query_service.find_by(id:) }.select(&:file_set?)

          expect(presenter.file_set_presenters)
            .to contain_exactly(*fs_members.map { |member| have_attributes(id: member.id) })
        end

        context 'and an ability' do
          include_context 'with assigned ability'

          it('is empty when the user cannot read any file sets') { expect(presenter.file_set_presenters).to be_empty }

          it 'has file sets the user can read' do
            readable = valkyrie_create(:hyrax_file_set, :with_files, :in_work, work: work, read_users: [user])

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
    it('gives an empty string for an unpersisted object') { expect(presenter.manifest_url).to be_empty }

    context 'with a persisted work' do
      let(:work) { valkyrie_create(:monograph) }

      it 'builds a url from the manifest path and work id ' do
        expect(presenter.manifest_url).to include "concern/monographs/#{work.id}/manifest"
      end
    end
  end

  describe '#sequence_rendering' do
    it('provides an empty sequence rendering') { expect(presenter.sequence_rendering).to eq([]) }

    context 'with file sets in a rendering sequence' do
      let(:work) { valkyrie_create(:monograph, uploaded_files: [FactoryBot.create(:uploaded_file), FactoryBot.create(:uploaded_file)]) }

      before do
        work.rendering_ids = work.member_ids
        Hyrax.persister.save(resource: work)
      end

      it('provides a sequence rendering for the file_sets') { expect(presenter.sequence_rendering.count).to eq 2 }
    end
  end

  describe '#work_presenters' do
    it('is empty') { expect(presenter.work_presenters).to be_empty } 

    context 'when the work has member works' do
      let(:work) { build(:monograph, :with_member_works) }

      it 'gives presenters for the members' do
        expect(presenter.work_presenters)
          .to contain_exactly(*work.member_ids.map { |id| have_attributes(id: id) })
      end

      context 'and file set members' do
        let(:work) { valkyrie_create(:monograph, :with_file_and_work) }

        it 'gives presenters only for the work members' do
          work_members = work.member_ids.map{ |id| Hyrax.query_service.find_by(id:) }.select(&:work?)

          expect(presenter.work_presenters)
            .to contain_exactly(*work_members.map { |member| have_attributes(id: member.id) })
        end
      end
    end
  end

  describe '#version' do
    let(:work) { valkyrie_create(:monograph) }

    it('returns a string') { expect(presenter.version).to be_a String }

    context 'when the work is unsaved' do
      let(:work) { build(:monograph) }

      it('is still a string') { expect(presenter.version).to be_a String }
    end
  end
end
