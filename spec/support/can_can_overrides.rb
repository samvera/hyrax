# frozen_string_literal: true
##
# This monkey-patch shim is for both active_fedora and valkyrie resources for tests
# This shim handles the case where controllers are loaded with an ActiveFedora collection class
# different than a test mocks Hyrax.config.collection_class.
# This override checks the value in Hyrax.config and uses it when it is a known collection or admin set class.
# This override also memoizes the resource_class to avoid multiple lookups.
CanCan::ControllerResource.class_eval do
  def resource_class
    return @resource_class if @resource_class.present?
    @resource_class = case @options[:class]
                      when false then
                        name.to_sym
                      when nil then
                        namespaced_name.to_s.camelize.constantize
                      when String then
                        @options[:class].constantize
                      else
                        @options[:class]
                      end
    @resource_class = dynamically_resolve_class(@resource_class)
  end

  private

  def dynamically_resolve_class(resource_class)
    if collection_class?(resource_class)
      Hyrax.config.collection_class
    elsif admin_set_class?(resource_class)
      Hyrax.config.admin_set_class
    else
      resource_class
    end
  end

  def collection_class?(model_class)
    model_class == Hyrax::PcdmCollection || model_class < Hyrax::PcdmCollection || model_class == ::Collection || model_class < ::Collection
  end

  def admin_set_class?(model_class)
    model_class == Hyrax::AdministrativeSet || model_class < Hyrax::AdministrativeSet || model_class == AdminSet || model_class < AdminSet
  end
end
