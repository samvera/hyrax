# frozen_string_literal: true
class Hyrax::DerivativeService
  # @deprecated favor Hyrax.config.derivative_services=
  def self.services=(services)
    Deprecation.warn("Hyrax::DerivativeService.services= is deprecated; favor Hyrax.config.derivative_servies=")
    Hyrax.config.derivative_services = Array(services)
  end

  # @deprecated favor Hyrax.config.derivative_services
  def self.services
    Deprecation.warn("Hyrax::DerivativeService.services is deprecated; favor Hyrax.config.derivative_servies")
    Hyrax.config.derivative_services
  end

  # @api public
  #
  # Get the first valid registered service for the given file_set.
  #
  # @param file_set [#uri, #file_set]
  # @return [#cleanup_derivatives, #create_derivatives, #derivative_url]
  def self.for(file_set, services: Hyrax.config.derivative_services)
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
