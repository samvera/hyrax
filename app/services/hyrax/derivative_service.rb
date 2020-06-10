# frozen_string_literal: true
class Hyrax::DerivativeService
  class_attribute :services
  self.services = [Hyrax::FileSetDerivativesService]
  def self.for(file_set)
    services.map { |service| service.new(file_set) }.find(&:valid?) ||
      new(file_set)
  end
  attr_reader :file_set
  delegate :mime_type, :uri, to: :file_set
  def initialize(file_set)
    @file_set = file_set
  end

  def cleanup_derivatives; end

  def create_derivatives(_file_path); end

  # What should this return?
  def derivative_url(_destination_name)
    ""
  end

  def valid?
    true
  end
end
