module CurationConcerns
  class CreateDerivativesService
    include Hydra::Derivatives

    def self.run(generic_file)
      new(generic_file).create_derivatives
    end

    delegate :logger, :transformation_schemes, :mime_type, :attached_files,
      :add_file, :id, to: :@generic_file

    def initialize(generic_file)
      @generic_file = generic_file
    end

  end
end
