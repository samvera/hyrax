require 'spec_helper'

describe CurationConcerns::FileSet do
  let(:file_set) { FileSet.create { |gf| gf.apply_depositor_metadata('jcoyne@example.com') } }

  before do
    allow(file_set).to receive(:mime_type).and_return(mime_type)
  end

  after do
    dir = File.join(CurationConcerns.config.derivatives_path, file_set.id)
    FileUtils.rm_r(dir) if File.directory?(dir)
  end

  describe 'image derivative' do
    let(:mime_type) { 'image/jp2' }
    let(:file_name) { File.join(fixture_path, 'image.jp2') }
    it 'only makes one thumbnail' do
      expect_any_instance_of(Hydra::Derivatives::Image).to receive(:process).once
      file_set.create_derivatives(file_name)
    end
  end

  describe 'pdf derivative' do
    let(:mime_type) { 'application/pdf' }
    let(:file_name) { File.join(fixture_path, 'test.pdf') }
    it 'only makes one thumbnail' do
      expect_any_instance_of(Hydra::Derivatives::Image).to receive(:process).once
      file_set.create_derivatives(file_name)
    end
  end

  describe 'office derivative' do
    let(:mime_type) { 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' }
    let(:file_name) { File.join(fixture_path, 'charter.docx') }
    it 'only makes one thumbnail' do
      expect_any_instance_of(Hydra::Derivatives::Document).to receive(:process).once
      file_set.create_derivatives(file_name)
    end
  end

  describe 'audiovisual transcoding', unless: $in_travis do
    before do
      # stub the name service so it's easer to find where the file will be
      allow(CurationConcerns::DerivativePath).to receive(:derivative_path_for_reference) do |object, key|
        "#{Rails.root}/tmp/derivatives/#{object.id}/#{key}.#{key}"
      end
    end

    context 'with a video (.avi) file' do
      let(:mime_type) { 'video/avi' }
      let(:file_name) { File.join(fixture_path, 'countdown.avi') }

      it 'transcodes to webm and mp4' do
        new_webm = "#{Rails.root}/tmp/derivatives/#{file_set.id}/webm.webm"
        new_mp4 = "#{Rails.root}/tmp/derivatives/#{file_set.id}/mp4.mp4"
        expect {
          file_set.create_derivatives(file_name)
        }.to change { File.exist?(new_webm) }
          .from(false).to(true)
          .and change { File.exist?(new_mp4) }
          .from(false).to(true)
      end
    end

    context 'with an audio (.wav) file' do
      let(:mime_type) { 'audio/wav' }
      let(:file_name) { File.join(fixture_path, 'piano_note.wav') }

      it 'transcodes to mp3 and ogg' do
        new_mp3 = "#{Rails.root}/tmp/derivatives/#{file_set.id}/mp3.mp3"
        new_ogg = "#{Rails.root}/tmp/derivatives/#{file_set.id}/ogg.ogg"
        expect {
          file_set.create_derivatives(file_name)
        }.to change { File.exist?(new_mp3) }
          .from(false).to(true)
          .and change { File.exist?(new_ogg) }
          .from(false).to(true)
      end
    end
  end
end
