# frozen_string_literal: true
require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::FileSetDerivativesService do
  context 'for active_fedora', :active_fedora do
    let(:valid_file_set) do
      FileSet.new.tap do |f|
        allow(f).to receive(:mime_type).and_return('image/png')
      end
    end

    it_behaves_like "a Hyrax::DerivativeService"
  end

  context 'for a valkyrie resource', valkyrie_adapter: :test_adapter do
    let(:valid_file_set) do
      FactoryBot.valkyrie_create(:hyrax_file_metadata, :image)
    end

    it_behaves_like "a Hyrax::DerivativeService"

    it "can get derivative mime type arrays" do
      expect(Hyrax.config.derivative_mime_type_mappings.values.map(&:class).uniq).to contain_exactly(Array)
    end

    describe "#create_derivatives" do
      context "when given an audio file" do
        let(:valid_file_set) do
          FactoryBot.valkyrie_create(:hyrax_file_metadata, :audio_file, file_set_id: SecureRandom.uuid)
        end

        it "passes a mime-type and container to the audio derivatives service" do
          allow(Hydra::Derivatives::AudioDerivatives).to receive(:create)
          described_class.new(valid_file_set).create_derivatives('foo')
          expect(Hydra::Derivatives::AudioDerivatives).to have_received(:create).with(
            'foo',
            outputs: contain_exactly(
              hash_including(mime_type: 'audio/mpeg', container: 'service_file'),
              hash_including(mime_type: 'audio/ogg', container: 'service_file')
            )
          )
        end
      end

      context "when an app overrides only the image thumbnail size" do
        let(:valid_file_set) do
          FactoryBot.valkyrie_create(:hyrax_file_metadata, :image, file_set_id: SecureRandom.uuid)
        end
        let(:custom_size) { '9999x9999' }

        before do
          allow(Hyrax.config).to receive(:derivative_options).and_return(
            image: [Hyrax::Configuration.new.derivative_options[:image].first.merge(size: custom_size)]
          )
        end

        it "creates the thumbnail at the configured size but keeps the other defaults" do
          allow(Hydra::Derivatives::ImageDerivatives).to receive(:create)
          described_class.new(valid_file_set).create_derivatives('foo.jpg')
          expect(Hydra::Derivatives::ImageDerivatives).to have_received(:create).with(
            'foo.jpg',
            outputs: contain_exactly(
              hash_including(size: custom_size, label: :thumbnail, format: 'jpg', layer: 0)
            )
          )
        end
      end

      context "when given a pdf file" do
        let(:valid_file_set) do
          FactoryBot.valkyrie_create(:hyrax_file_metadata, mime_type: 'application/pdf', file_set_id: SecureRandom.uuid)
        end

        before do
          allow(Hydra::Derivatives::PdfDerivatives).to receive(:create)
          allow(Hydra::Derivatives::FullTextExtract).to receive(:create)
        end

        it "creates the thumbnail and extracts full text" do
          described_class.new(valid_file_set).create_derivatives('foo.pdf')
          expect(Hydra::Derivatives::PdfDerivatives).to have_received(:create).with(
            'foo.pdf', outputs: contain_exactly(hash_including(label: :thumbnail))
          )
          expect(Hydra::Derivatives::FullTextExtract).to have_received(:create).with(
            'foo.pdf', outputs: contain_exactly(hash_including(container: 'extracted_text'))
          )
        end

        context "when the extracted_text output is removed from the config" do
          before do
            pdf_without_text = Hyrax::Configuration.new.derivative_options[:pdf].reject { |o| o[:container] == 'extracted_text' }
            allow(Hyrax.config).to receive(:derivative_options).and_return(pdf: pdf_without_text)
          end

          it "still creates the thumbnail but skips full text extraction" do
            described_class.new(valid_file_set).create_derivatives('foo.pdf')
            expect(Hydra::Derivatives::PdfDerivatives).to have_received(:create).with(
              'foo.pdf', outputs: contain_exactly(hash_including(label: :thumbnail))
            )
            expect(Hydra::Derivatives::FullTextExtract).not_to have_received(:create)
          end
        end
      end

      context "when given a video file" do
        let(:valid_file_set) do
          FactoryBot.valkyrie_create(:hyrax_file_metadata, :video_file, file_set_id: SecureRandom.uuid)
        end

        it "passes a mime-type to the video derivatives service" do
          allow(Hydra::Derivatives::VideoDerivatives).to receive(:create)
          described_class.new(valid_file_set).create_derivatives('foo')
          expect(Hydra::Derivatives::VideoDerivatives).to have_received(:create).with(
            'foo',
            outputs: contain_exactly(
              hash_including(mime_type: 'video/mp4', container: 'service_file'),
              hash_including(mime_type: 'video/webm', container: 'service_file'),
              hash_including(mime_type: 'image/jpeg')
            )
          )
        end

        context "when an output size is a callable" do
          let(:received_file_set) { [] }

          before do
            size_from = ->(file_set) { received_file_set << file_set && '1280x720' }
            sized = Hyrax::Configuration.new.derivative_options[:video].map { |output| output.merge(size: size_from) }
            allow(Hyrax.config).to receive(:derivative_options).and_return(video: sized)
          end

          it "invokes it with the file set and passes the result through" do
            allow(Hydra::Derivatives::VideoDerivatives).to receive(:create)
            described_class.new(valid_file_set).create_derivatives('foo.mov')

            expect(received_file_set).to all(eq(valid_file_set))
            expect(Hydra::Derivatives::VideoDerivatives).to have_received(:create) do |_filename, outputs:|
              expect(outputs).to all(include(size: '1280x720'))
            end
          end
        end
      end
    end
  end
end
