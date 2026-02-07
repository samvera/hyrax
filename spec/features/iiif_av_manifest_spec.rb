# frozen_string_literal: true

RSpec.describe 'building a IIIF AV Manifest', :aggregate_failures do
  let(:work) { valkyrie_create(:monograph, :public, title: ['AV Test Work'], members: file_sets) }
  let(:user) { create(:admin) }

  before do
    allow(Flipflop).to receive(:iiif_av?).and_return(true)
  end

  context 'with video file set' do
    let(:uploaded_file) { FactoryBot.create(:uploaded_file, file: file_fixture('sample_mpeg4.mp4').open) }
    let(:file_sets) do
      valkyrie_create_list(:hyrax_file_set, 1).map do |file_set|
        valkyrie_create(:hyrax_file_metadata, :original_file, :video_file, :with_file,
                        original_filename: 'sample_video.mp4',
                        mime_type: 'video/mp4',
                        duration: '60000',
                        file_set: file_set,
                        file: uploaded_file)
        Hyrax.persister.save(resource: file_set)
      end
    end

    it 'generates a v3 manifest with video content' do
      sign_in user
      visit "/concern/monographs/#{work.id}/manifest"

      manifest_json = JSON.parse(page.body)

      # Verify v3 structure
      expect(manifest_json['@context']).to include('http://iiif.io/api/presentation/3/context.json')
      expect(manifest_json['type']).to eq('Manifest')
      expect(manifest_json['label']).to be_present

      # v3 uses 'items' instead of 'sequences'
      expect(manifest_json['items'].size).to eq 1

      canvas = manifest_json['items'].first
      expect(canvas['type']).to eq('Canvas')

      # Check for video annotation
      annotation_page = canvas['items'].first
      expect(annotation_page['type']).to eq('AnnotationPage')

      annotation = annotation_page['items'].first
      expect(annotation['motivation']).to eq('painting')

      # Verify video body
      body = annotation['body']
      body = [body] unless body.is_a?(Array) # normalize to array

      video_content = body.first
      expect(video_content['type']).to eq('Video')
      expect(video_content['format']).to eq('video/mp4')
      expect(video_content['id']).to include('/iiif_av/content/')
    end
  end

  context 'with audio file set' do
    let(:uploaded_file) { FactoryBot.create(:uploaded_file, file: file_fixture('hyrax/hyrax_test5.mp3').open) }
    let(:file_sets) do
      valkyrie_create_list(:hyrax_file_set, 1) .map do |file_set|
        valkyrie_create(:hyrax_file_metadata, :original_file, :audio_file, :with_file,
                        original_filename: 'hyrax_test5.mp3',
                        mime_type: 'audio/mpeg',
                        duration: '60000',
                        file_set: file_set,
                        file: uploaded_file)
        Hyrax.persister.save(resource: file_set)
      end
    end

    context 'when using UniversalViewer' do
      it 'generates a v3 manifest with audio content' do
        allow(Hyrax.config).to receive(:iiif_av_viewer).and_return(:universal_viewer)
        sign_in user
        visit "/concern/monographs/#{work.id}/manifest"
        manifest_json = JSON.parse(page.body)

        expect(manifest_json['@context']).to include('http://iiif.io/api/presentation/3/context.json')

        canvas = manifest_json['items'].first
        annotation = canvas['items'].first['items'].first
        body = annotation['body']
        body = [body] unless body.is_a?(Array)

        audio_content = body.first
        expect(audio_content['type']).to eq('Sound')
        expect(audio_content['format']).to eq('audio/mp3')
      end
    end

    context 'when using another viewer' do
      it 'generates a v3 manifest with audio content' do
        allow(Hyrax.config).to receive(:iiif_av_viewer).and_return(:another_viewer)
        sign_in user
        visit "/concern/monographs/#{work.id}/manifest"
        manifest_json = JSON.parse(page.body)

        expect(manifest_json['@context']).to include('http://iiif.io/api/presentation/3/context.json')

        canvas = manifest_json['items'].first
        annotation = canvas['items'].first['items'].first
        body = annotation['body']
        body = [body] unless body.is_a?(Array)

        audio_content = body.first
        expect(audio_content['type']).to eq('Sound')
        expect(audio_content['format']).to eq('audio/mpeg')
      end
    end
  end

  context 'when iiif_av flipper is disabled' do
    before do
      allow(Flipflop).to receive(:iiif_av?).and_return(false)
    end

    let(:uploaded_file) { FactoryBot.create(:uploaded_file, file: file_fixture('sample_mpeg4.mp4').open) }
    let(:file_sets) do
      valkyrie_create_list(:hyrax_file_set, 1).map do |file_set|
        valkyrie_create(:hyrax_file_metadata, :original_file, :video_file, :with_file,
                        original_filename: 'sample_video.mp4',
                        mime_type: 'video/mp4',
                        duration: '60000',
                        file_set: file_set,
                        file: uploaded_file)
        Hyrax.persister.save(resource: file_set)
      end
    end

    it 'generates a v2 manifest (default behavior)' do
      sign_in user
      visit "/concern/monographs/#{work.id}/manifest"
      manifest_json = JSON.parse(page.body)

      expect(manifest_json['@context']).to eq('http://iiif.io/api/presentation/2/context.json')
    end
  end
end
