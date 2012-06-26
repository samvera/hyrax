require 'deprecation'
module Hydra::InlineEditableMetadataHelperBehavior
  extend Deprecation
  
  def inline_editable_text_field(object_name, method, options = {})
  end
  deprecation_deprecate :inline_editable_text_field
  
  def inline_editable_text_area(object_name, method, options = {})
  end
  deprecation_deprecate :inline_editable_text_area
  
  def inline_editable_select(object_name, method, options = {})
  end
  deprecation_deprecate :inline_editable_select
  
  def inline_editable_checkbox(object_name, method, options = {})
  end
  deprecation_deprecate :inline_editable_checkbox
  
end
