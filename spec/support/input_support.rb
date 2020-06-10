# frozen_string_literal: true
module InputSupport
  extend ActiveSupport::Concern

  include RSpec::Rails::HelperExampleGroup

  def input_for(object, attribute_name, options = {})
    helper.simple_form_for object, url: '' do |f|
      f.input attribute_name, options
    end
  end
end
