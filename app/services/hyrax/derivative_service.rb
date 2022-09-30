# frozen_string_literal: true

# @api public
#
# A factory class _and_ interface defining class that finds the **first** valid registered service for the given object.
#
# The .for method is the factory.  The instance_methods of this class defines the interface.
#
# @see https://github.com/samvera-labs/newspaper_works/blob/d0c0c0595ad318178896fb7f2abd93c5139fe5b7/lib/newspaper_works/engine.rb#L15-L35 for an example extending the service.
# @see ValkyrieCreateDerivativesJob for example of this object's usage within Hyrax
# @see Hyrax::FileSet::Derivatives for example of this object's usage within Hyrax
# @see Hyrax::FileSetDerivativesService for a class that implements the Hyrax::DerivativeService interface
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

  # @api private
  def initialize(file_set)
    @file_set = file_set
  end

  # @api public
  def cleanup_derivatives; end

  # @api public
  def create_derivatives(_file_path); end

  # @api public
  # @note What should this return?
  def derivative_url(_destination_name)
    ""
  end

  # @api public
  def valid?
    true
  end
end
