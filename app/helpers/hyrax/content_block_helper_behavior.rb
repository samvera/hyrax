# frozen_string_literal: true
module Hyrax
  module ContentBlockHelperBehavior
    def displayable_content_block(content_block, **options)
      return unless display_content_block? content_block
      tag.div(raw(content_block.value), **options)
    end

    def display_content_block?(content_block)
      content_block.present? && content_block.value.present?
    end
  end
end
