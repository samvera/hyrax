require 'spec_helper'

describe CreateDerivativesJob do
  before do
    @ffmpeg_enabled = Sufia.config.enable_ffmpeg
    Sufia.config.enable_ffmpeg = true
    @generic_file = GenericFile.new.tap do |gf|
      gf.apply_depositor_metadata('jcoyne@example.com')
      gf.save
    end
  end

  after do
    Sufia.config.enable_ffmpeg = @ffmpeg_enabled
    @generic_file.destroy
  end

  subject { CreateDerivativesJob.new(@generic_file.id) }

  describe 'thumbnail generation' do
    context 'with a video (.avi) file', unless: $in_travis do
      before do
        @generic_file.add_file(File.open(fixture_path + '/countdown.avi'), 'content', 'countdown.avi')
        allow_any_instance_of(GenericFile).to receive(:mime_type).and_return('video/avi')
        @generic_file.save!
      end

      it 'lacks a thumbnail' do
        expect(@generic_file.thumbnail).not_to have_content
      end

      it 'generates a thumbnail on job run' do
        subject.run
        @generic_file.reload
        expect(@generic_file.thumbnail).to have_content
        expect(@generic_file.thumbnail.mime_type).to eq('image/jpeg')
      end
    end

    context 'with an audio (.wav) file', unless: $in_travis do
      before do
        @generic_file.add_file(File.open(fixture_path + '/piano_note.wav'), 'content', 'piano_note.wav')
        allow_any_instance_of(GenericFile).to receive(:mime_type).and_return('audio/wav')
        @generic_file.save!
      end

      it 'lacks a thumbnail' do
        expect(@generic_file.thumbnail).not_to have_content
      end

      it 'does not generate a thumbnail on job run' do
        subject.run
        @generic_file.reload
        expect(@generic_file.thumbnail).not_to have_content
      end
    end

    context 'with an image (.jp2) file' do
      before do
        @generic_file.add_file(File.open(fixture_path + '/image.jp2'), 'content', 'image.jp2')
        allow_any_instance_of(GenericFile).to receive(:mime_type).and_return('image/jp2')
        @generic_file.save!
      end

      it 'lacks a thumbnail' do
        expect(@generic_file.thumbnail).not_to have_content
      end

      it 'generates a thumbnail on job run' do
        subject.run
        @generic_file.reload
        expect(@generic_file.thumbnail).to have_content
        expect(@generic_file.thumbnail.mime_type).to eq('image/jpeg')
      end
    end

    context 'with an office document (.docx) file', unless: $in_travis do
      before do
        @generic_file.add_file(File.open(fixture_path + '/charter.docx'), 'content', 'charter.docx')
        allow_any_instance_of(GenericFile).to receive(:mime_type).and_return('application/vnd.openxmlformats-officedocument.wordprocessingml.document')
        @generic_file.save!
      end

      it 'lacks a thumbnail' do
        expect(@generic_file.thumbnail).not_to have_content
      end

      it 'generates a thumbnail on job run' do
        subject.run
        @generic_file.reload
        expect(@generic_file.thumbnail).to have_content
        expect(@generic_file.thumbnail.mime_type).to eq('image/jpeg')
      end
    end
  end

  describe 'audiovisual transcoding' do
    context 'with a video (.avi) file', unless: $in_travis do
      before do
        @generic_file.add_file(File.open(fixture_path + '/countdown.avi'), 'content', 'countdown.avi')
        allow_any_instance_of(GenericFile).to receive(:mime_type).and_return('video/avi')
        @generic_file.save!
      end

      it 'transcodes to webm and mp4' do
        subject.run
        reloaded = @generic_file.reload
        derivative = reloaded.datastreams['webm']
        expect(derivative).not_to be_nil
        expect(derivative.content).not_to be_nil
        expect(derivative.mime_type).to eq('video/webm')

        derivative2 = reloaded.datastreams['mp4']
        expect(derivative2).not_to be_nil
        expect(derivative2.content).not_to be_nil
        expect(derivative2.mime_type).to eq('video/mp4')
      end
    end

    context 'with an audio (.wav) file', unless: $in_travis do
      before do
        @generic_file.add_file(File.open(fixture_path + '/piano_note.wav'), 'content', 'piano_note.wav')
        allow_any_instance_of(GenericFile).to receive(:mime_type).and_return('audio/wav')
        @generic_file.save!
      end

      it 'transcodes to mp3 and ogg' do
        subject.run
        reloaded = @generic_file.reload
        derivative = reloaded.datastreams['mp3']
        expect(derivative).not_to be_nil
        expect(derivative.content).not_to be_nil
        expect(derivative.mime_type).to eq('audio/mpeg')

        derivative2 = reloaded.datastreams['ogg']
        expect(derivative2).not_to be_nil
        expect(derivative2.content).not_to be_nil
        expect(derivative2.mime_type).to eq('audio/ogg')
      end
    end

    describe 'with an mp3 file' do
      # Uncomment when this is no longer pending
      # before do
      #   @generic_file.add_file(File.open(fixture_path + '/sufia/sufia_test5.mp3'), 'content', 'sufia_test5.mp3')
      #   @generic_file.save!
      # end

      it 'should copy the content to the mp3 datastream and transcode to ogg' do
        pending 'Need a way to do this in hydra-derivatives'
        subject.run
        reloaded = @generic_file.reload
        derivative = reloaded.datastreams['mp3']
        expect(derivative.content.size).to eq(reloaded.content.content.size)
        expect(derivative.mime_type).to eq('audio/mpeg')

        derivative2 = reloaded.datastreams['ogg']
        expect(derivative2.content).not_to be_nil
        expect(derivative2.mime_type).to eq('audio/ogg')
      end
    end

    describe 'with an ogg file' do
      # Uncomment when this is no longer pending
      # before do
      #   @generic_file.add_file(File.open(fixture_path + '/Example.ogg'), 'content', 'Example.ogg')
      #   @generic_file.save!
      # end

      it 'should copy the content to the ogg datastream and transcode to mp3' do
        pending 'Need a way to do this in hydra-derivatives'
        subject.run
        reloaded = @generic_file.reload
        derivative = reloaded.datastreams['mp3']
        expect(derivative).not_to be_nil
        expect(derivative.content).not_to be_nil
        expect(derivative.mimeType).to eq('audio/mpeg')

        derivative2 = reloaded.datastreams['ogg']
        expect(derivative2).not_to be_nil
        expect(derivative2.content.size).to eq(reloaded.content.content.size)
        expect(derivative2.mime_type).to eq('audio/ogg')
      end
    end
  end
end
