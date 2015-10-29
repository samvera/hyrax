module Sufia
  class CreateDerivativesService
    include Hydra::Derivatives

    def self.run(file_set)
      new(file_set).create_derivatives
    end

    delegate :logger, :transformation_schemes, :mime_type, :attached_files,
             :add_file, :id, to: :@file_set

    def initialize(file_set)
      @file_set = file_set
    end
  end
end
