# frozen_string_literal: true

module Blacklight
  class Configuration::FacetField < Blacklight::Configuration::Field
    def normalize!(blacklight_config = nil)
      super
      self.presenter ||= Blacklight::FacetFieldPresenter
      self.item_presenter ||= Blacklight::FacetItemPresenter
      self.component = Blacklight::FacetFieldListComponent if component.nil? || component == true
      self.item_component ||= pivot ? Blacklight::FacetItemPivotComponent : Blacklight::FacetItemComponent
      self
    end
  end
end
