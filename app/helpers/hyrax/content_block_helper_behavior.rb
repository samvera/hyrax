module Hyrax
  module ContentBlockHelperBehavior
    def displayable_content_block(content_block, **options)
      return if content_block.value.blank?
      content_tag :div, raw(content_block.value), options
    end

    def display_content_block?(content_block)
      content_block.value.present?
    end
  end
end
