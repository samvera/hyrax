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
    let(:solr_doc) { SolrDocument.new(Hyrax::Indexers::ResourceIndexer.for(resource: file_set).to_solr) }

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
          index_hash = Hyrax::Indexers::ResourceIndexer.for(resource: file_set).to_solr
          index_hash.delete('original_file_id_ssi')

          SolrDocument.new(index_hash)
        end

        shared_examples 'tests for image resolution'
      end

      context 'when using v3 manifest factory' do
        before do
          allow(Hyrax.config).to receive(:iiif_manifest_factory).and_return(::IIIFManifest::V3::ManifestFactory)
        end

        it 'returns nil to avoid duplicate annotations (display_content handles v3 images)' do
          expect(presenter.display_image).to be_nil
        end
      end
    end

    describe '#display_content' do
      let(:ability) { Ability.new(user) }
      let(:user) { create(:user) }
      let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set, :public) }

      subject(:presenter) { described_class.new(solr_doc) }

      before do
        presenter.hostname = 'samvera.org'
        presenter.ability = ability
        allow(Flipflop).to receive(:iiif_av?).and_return(true)
      end

      context 'when flipper is disabled' do
        let(:solr_doc) { SolrDocument.new(Hyrax::Indexers::ResourceIndexer.for(resource: file_set).to_solr) }

        before { allow(Flipflop).to receive(:iiif_av?).and_return(false) }

        it { expect(presenter.display_content).to be_nil }
      end

      context 'when user cannot read' do
        let(:solr_doc) { SolrDocument.new(Hyrax::Indexers::ResourceIndexer.for(resource: file_set).to_solr) }

        before do
          allow(ability).to receive(:can?).with(:read, anything).and_return(false)
        end

        it { expect(presenter.display_content).to be_nil }
      end

      context 'with video file' do
        let(:original_file_metadata) do
          valkyrie_create(:hyrax_file_metadata, :original_file, :with_file,
                          file_set: file_set,
                          mime_type: 'video/mp4',
                          width: 1920,
                          height: 1080,
                          duration: ['120'])
        end

        let(:solr_doc) do
          original_file_metadata
          solr_hash = Hyrax::Indexers::ResourceIndexer.for(resource: file_set).to_solr
          solr_hash['mime_type_ssi'] = 'video/mp4'
          solr_hash['width_is'] = 1920
          solr_hash['height_is'] = 1080
          solr_hash['duration_tesim'] = ['120']
          SolrDocument.new(solr_hash)
        end

        it 'returns video display content' do
          content = presenter.display_content

          expect(content).to be_a(IIIFManifest::V3::DisplayContent)
          expect(content.type).to eq('Video')
          expect(content.format).to eq('video/mp4')
          expect(content.url).to include("samvera.org/downloads/#{file_set.id}")
          expect(content.thumbnail).to contain_exactly(
            hash_including(type: 'Image', format: 'image/jpeg')
          )
        end
      end

      context 'with audio file' do
        let(:original_file_metadata) do
          valkyrie_create(:hyrax_file_metadata, :original_file, :with_file,
                          file_set: file_set,
                          mime_type: 'audio/mpeg',
                          duration: ['180'])
        end

        let(:solr_doc) do
          original_file_metadata
          solr_hash = Hyrax::Indexers::ResourceIndexer.for(resource: file_set).to_solr
          solr_hash['mime_type_ssi'] = 'audio/mpeg'
          solr_hash['duration_tesim'] = ['180']
          SolrDocument.new(solr_hash)
        end

        context 'when using UniversalViewer' do
          it 'returns audio display content' do
            allow(Hyrax.config).to receive(:iiif_av_viewer).and_return(:universal_viewer)
            content = presenter.display_content

            expect(content).to be_a(IIIFManifest::V3::DisplayContent)
            expect(content.type).to eq('Sound')
            expect(content.format).to eq('audio/mp3')
            expect(content.url).to include("samvera.org/downloads/#{file_set.id}")
            expect(content.thumbnail).to contain_exactly(
              hash_including(type: 'Image', format: 'image/png')
            )
          end
        end

        context 'when using non-UniversalViewer' do
          it 'returns audio display content' do
            allow(Hyrax.config).to receive(:iiif_av_viewer).and_return(:some_other_viewer)
            content = presenter.display_content

            expect(content).to be_a(IIIFManifest::V3::DisplayContent)
            expect(content.type).to eq('Sound')
            expect(content.format).to eq('audio/mpeg')
            expect(content.url).to include("downloads/#{file_set.id}")
            expect(content.thumbnail).to contain_exactly(
              hash_including(type: 'Image', format: 'image/png')
            )
          end
        end
      end

      context 'with image file' do
        let(:solr_doc) do
          original_file_metadata
          SolrDocument.new(Hyrax::Indexers::ResourceIndexer.for(resource: file_set).to_solr)
        end

        before do
          allow(Hyrax.config).to receive(:iiif_manifest_factory).and_return(::IIIFManifest::V3::ManifestFactory)
        end

        it 'returns image display content when using v3 factory' do
          content = presenter.display_content

          expect(content).to be_a(IIIFManifest::V3::DisplayContent)
          expect(content.type).to eq('Image')
        end

        context 'when using v2 factory' do
          before do
            allow(Hyrax.config).to receive(:iiif_manifest_factory)
              .and_return(::IIIFManifest::ManifestFactory)
          end

          it 'returns nil to let display_image handle v2' do
            expect(presenter.display_content).to be_nil
          end
        end

        context 'with pdf file' do
          let(:original_file_metadata) do
            valkyrie_create(:hyrax_file_metadata, :original_file, :with_file,
                            file_set: file_set,
                            mime_type: 'application/pdf')
          end

          let(:solr_doc) do
            original_file_metadata
            solr_hash = Hyrax::Indexers::ResourceIndexer.for(resource: file_set).to_solr
            solr_hash['mime_type_ssi'] = 'application/pdf'
            SolrDocument.new(solr_hash)
          end

          before do
            allow(Flipflop).to receive(:iiif_pdf?).and_return(true)
          end

          it 'returns pdf display content' do
            content = presenter.display_content

            expect(content).to be_a(IIIFManifest::V3::DisplayContent)
            expect(content.type).to eq('Text')
            expect(content.format).to eq('application/pdf')
            expect(content.url).to include("downloads/#{file_set.id}")
            expect(content.thumbnail).to contain_exactly(
              hash_including(type: 'Image', format: 'image/jpeg')
            )
          end

          context 'when iiif_pdf flipper is disabled' do
            before { allow(Flipflop).to receive(:iiif_pdf?).and_return(false) }

            it { expect(presenter.display_content).to be_nil }
          end
        end
      end

      describe 'duration formatting' do
        let(:original_file_metadata) do
          valkyrie_create(:hyrax_file_metadata, :original_file, :with_file,
                          file_set: file_set,
                          mime_type: 'video/mp4')
        end

        context 'with duration as plain milliseconds' do
          let(:solr_doc) do
            original_file_metadata
            solr_hash = Hyrax::Indexers::ResourceIndexer.for(resource: file_set).to_solr
            solr_hash['mime_type_ssi'] = 'video/mp4'
            solr_hash['duration_tesim'] = ['120000']
            SolrDocument.new(solr_hash)
          end

          it 'converts milliseconds to seconds' do
            content = presenter.display_content
            expect(content.duration).to eq(120.0)
          end
        end

        context 'with duration as plain milliseconds (large value)' do
          let(:solr_doc) do
            original_file_metadata
            solr_hash = Hyrax::Indexers::ResourceIndexer.for(resource: file_set).to_solr
            solr_hash['mime_type_ssi'] = 'video/mp4'
            solr_hash['duration_tesim'] = ['30527']
            SolrDocument.new(solr_hash)
          end

          it 'converts milliseconds to seconds' do
            content = presenter.display_content
            expect(content.duration).to eq(30.527)
          end
        end

        context 'with duration in seconds with unit suffix' do
          let(:solr_doc) do
            original_file_metadata
            solr_hash = Hyrax::Indexers::ResourceIndexer.for(resource: file_set).to_solr
            solr_hash['mime_type_ssi'] = 'video/mp4'
            solr_hash['duration_tesim'] = ['25 s']
            SolrDocument.new(solr_hash)
          end

          it 'converts to seconds' do
            content = presenter.display_content
            expect(content.duration).to eq(25.0)
          end
        end

        context 'with duration in time format' do
          let(:solr_doc) do
            original_file_metadata
            solr_hash = Hyrax::Indexers::ResourceIndexer.for(resource: file_set).to_solr
            solr_hash['mime_type_ssi'] = 'video/mp4'
            solr_hash['duration_tesim'] = ['0:02:00']
            SolrDocument.new(solr_hash)
          end

          it 'converts to seconds' do
            content = presenter.display_content
            expect(content.duration).to eq(120.0)
          end
        end

        context 'with duration including milliseconds' do
          let(:solr_doc) do
            original_file_metadata
            solr_hash = Hyrax::Indexers::ResourceIndexer.for(resource: file_set).to_solr
            solr_hash['mime_type_ssi'] = 'video/mp4'
            solr_hash['duration_tesim'] = ['0:0:02:500']
            SolrDocument.new(solr_hash)
          end

          it 'converts to seconds with milliseconds' do
            content = presenter.display_content
            expect(content.duration).to eq(2.5)
          end
        end
      end
    end

    describe '#annotation_content' do
      let(:ability) { Ability.new(user) }
      let(:user) { create(:user) }
      let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set, :public) }
      let(:work) { valkyrie_create(:monograph, members: [file_set, vtt_file_set]) }

      let(:vtt_file_metadata) do
        valkyrie_create(:hyrax_file_metadata, :original_file, :with_file,
                        file_set: vtt_file_set,
                        original_filename: 'sample.vtt',
                        mime_type: 'text/vtt')
      end

      let(:vtt_file_set) do
        FactoryBot.valkyrie_create(:hyrax_file_set,
                                   :public,
                                   title: ['English Captions'],
                                   language: language)
      end
      
      let(:language) { [] }

      let(:solr_doc) do
        vtt_file_metadata
        work # ensure work is created with members

        solr_hash = Hyrax::Indexers::ResourceIndexer.for(resource: file_set).to_solr
        solr_hash['mime_type_ssi'] = 'video/mp4'
        solr_hash['duration_tesim'] = ['120']
        SolrDocument.new(solr_hash)
      end

      subject(:presenter) { described_class.new(solr_doc) }

      before do
        presenter.hostname = 'samvera.org'
        presenter.ability = ability
      end

      context 'with video file and vtt file set' do
        before do
          allow(solr_doc).to receive(:transcript_ids).and_return([vtt_file_set.id.to_s])
        end
        
        it 'returns transcription annotations' do
          annotations = presenter.annotation_content

          expect(annotations).to be_an(Array)
          expect(annotations.first).to be_a(IIIFManifest::V3::AnnotationContent)
          expect(annotations.first.type).to eq('Annotation')
          expect(annotations.first.motivation).to eq('supplementing')
          expect(annotations.first.format).to eq('text/vtt')
          expect(annotations.first.language).to eq('en')
          expect(annotations.first.label).to eq('English Captions')
          expect(annotations.first.body_id).to include('transcriptions')
          expect(annotations.first.body_id).to end_with('.vtt')
        end

        context 'when transcript has language' do
          context 'with a 3-letter language code' do
            let(:language) { ['eng'] }

            it 'returns the 2-letter language code' do
              annotations = presenter.annotation_content
              expect(annotations.first.language).to eq('en')
            end
          end

          context 'with 2-letter language code' do
            let(:language) { ['en'] }

            it 'returns the 2-letter language code' do
              annotations = presenter.annotation_content
              expect(annotations.first.language).to eq('en')
            end
          end

          context 'with a URI' do
            let(:language) { ['http://id.loc.gov/vocabulary/iso639-3/zho'] }

            it 'returns the 2-letter language code' do
              annotations = presenter.annotation_content
              expect(annotations.first.language).to eq('zh')
            end
          end

          context 'with a language name' do
            let(:language) { ['German'] }

            it 'returns the 2-letter language code' do
              annotations = presenter.annotation_content
              expect(annotations.first.language).to eq('de')
            end
          end

          context 'with no parseable language' do
            let(:language) { ['xyz'] }

            it 'falls back to en' do
              annotations = presenter.annotation_content
              expect(annotations.first.language).to eq('en')
            end
          end

          context 'with a locale' do
            let(:vtt_file_set) do
              FactoryBot.valkyrie_create(:hyrax_file_set,
                                         :public,
                                         title: ['English Captions'],
                                         language: ['en'])
            end
            let(:vtt_file_set_2) do
              FactoryBot.valkyrie_create(:hyrax_file_set,
                                         :public,
                                         title: ['English Captions'],
                                         language: ['ur'])
            end
            
            let!(:vtt_file_metadata_2) do
              valkyrie_create(:hyrax_file_metadata, :original_file, :with_file,
                              file_set: vtt_file_set_2,
                              original_filename: 'sample.vtt',
                              mime_type: 'text/vtt')
            end

            let(:work) { valkyrie_create(:monograph, members: [file_set, vtt_file_set, vtt_file_set_2]) }

            before do
              allow(solr_doc).to receive(:transcript_ids).and_return(
                [vtt_file_set.id.to_s, vtt_file_set_2.id.to_s]
              )
              allow(I18n).to receive(:locale).and_return(:ur)
            end

            it 'moves the current locale/language to the top of the transcript list' do
              expect(presenter.annotation_content.map(&:language)).to eq ['ur','en']
            end
          end
        end
      end

      context 'with video file but no vtt file sets' do
        let(:work) { valkyrie_create(:monograph, members: [file_set]) }

        it 'returns empty array' do
          annotations = presenter.annotation_content

          expect(annotations).to eq([])
        end
      end

      context 'with non-video/audio file' do
        let(:image_file_metadata) do
          valkyrie_create(:hyrax_file_metadata, :original_file, :image, :with_file,
                          file_set: file_set)
        end

        let(:solr_doc) do
          image_file_metadata
          SolrDocument.new(Hyrax::Indexers::ResourceIndexer.for(resource: file_set).to_solr)
        end

        it 'returns nil' do
          expect(presenter.annotation_content).to be_nil
        end
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

            allow_any_instance_of(Hyrax::IiifManifestPresenter::DisplayImagePresenter)
              .to receive(:display_image).and_return(double('DisplayImage'))

            expect(presenter.file_set_presenters)
              .to contain_exactly(have_attributes(id: readable.id))
          end
        end
      end
    end

    context 'when the work has both displayable and non-displayable file sets' do
      let(:text_file_metadata) do
        valkyrie_create(:hyrax_file_metadata, :original_file, :with_file,
                        file_set: text_file_set,
                        mime_type: 'text/plain')
      end

      let(:text_file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }
      let(:work) { valkyrie_create(:monograph, members: [file_set, text_file_set, second_file_set]) }

      before do
        original_file_metadata
        second_file_metadata
        text_file_metadata
      end

      it 'only includes file sets with displayable content' do
        expect(presenter.file_set_presenters.count).to eq 2
        expect(presenter.file_set_presenters.map(&:id))
          .to contain_exactly(file_set.id, second_file_set.id)
        expect(presenter.file_set_presenters.map(&:id))
          .not_to include(text_file_set.id)
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
