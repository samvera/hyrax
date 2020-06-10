# frozen_string_literal: true
module Hyrax
  class FileSet
    module Derivatives
      extend ActiveSupport::Concern

      included do
        # TODO: These should be moved to an initializer. However, there is a timing bug in place.
        #       If the following Hydra::Derivatives configuration is moved to an initializer, then the
        #       Hydra::Works configuration obliterates our new configuration.
        #       https://github.com/samvera/hydra-works/blob/d0e87d017c20ffbecbaeda8c09b376747b9cdebc/lib/hydra/works/models/concerns/file_set/derivatives.rb
        #
        #       This manifests as the following errors:
        #
        #       The following errors were encountered by moving the following class variables
        #       Failures:
        #
        #       1) IngestFileJob with two existing versions from different users has two versions
        #          Failure/Error: yield ::File.open(file_name)
        #
        #          KeyError:
        #            key not found: :object
        #          # ./app/services/hyrax/local_file_service.rb:7:in `call'
        #          # ./app/services/hyrax/file_set_derivatives_service.rb:60:in `create_image_derivatives'
        #          # ./app/services/hyrax/file_set_derivatives_service.rb:24:in `create_derivatives'
        #          # ./app/models/concerns/hyrax/file_set/derivatives.rb:11:in `create_derivatives'
        #          # ./app/jobs/create_derivatives_job.rb:11:in `perform'
        #          # ./app/jobs/characterize_job.rb:15:in `perform'
        #          # ./app/jobs/ingest_file_job.rb:35:in `perform'
        #          # ./spec/jobs/ingest_file_job_spec.rb:61:in `block (3 levels) in <top (required)>'
        #
        #       2) CreateDerivativesJob with a pdf file searches the extracted content
        #          Failure/Error: yield ::File.open(file_name)
        #
        #          KeyError:
        #            key not found: :object
        #          # ./app/services/hyrax/local_file_service.rb:7:in `call'
        #          # ./app/services/hyrax/file_set_derivatives_service.rb:31:in `create_pdf_derivatives'
        #          # ./app/services/hyrax/file_set_derivatives_service.rb:20:in `create_derivatives'
        #          # ./app/models/concerns/hyrax/file_set/derivatives.rb:11:in `create_derivatives'
        #          # ./app/jobs/create_derivatives_job.rb:11:in `perform'
        #          # ./spec/jobs/create_derivatives_job_spec.rb:88:in `block (3 levels) in <top (required)>'
        #          # ./spec/jobs/create_derivatives_job_spec.rb:7:in `block (2 levels) in <top (required)>'
        #
        Hydra::Derivatives.source_file_service = Hyrax::LocalFileService
        Hydra::Derivatives.output_file_service = Hyrax::PersistDerivatives
        Hydra::Derivatives::FullTextExtract.output_file_service = Hyrax::PersistDirectlyContainedOutputFileService
        before_destroy :cleanup_derivatives
        # This completely overrides the version in Hydra::Works so that we
        # read and write to a local file. It's important that characterization runs
        # before derivatives so that we have a credible mime_type field to work with.
        delegate :cleanup_derivatives, :create_derivatives, to: :file_set_derivatives_service
      end

      private

      def file_set_derivatives_service
        Hyrax::DerivativeService.for(self)
      end
    end
  end
end
