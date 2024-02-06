# frozen_string_literal: true
module Hyrax
  # Draws a collapsable list widget using the Bootstrap 3 / Collapse.js plugin
  class CollapsableSectionPresenter
    # rubocop:disable Metrics/ParameterLists
    def initialize(view_context:, text:, id:, icon_class:, open:, title: nil)
      @view_context = view_context
      @text = text
      @id = id
      @icon_class = icon_class
      @open = open
      @title = title
    end
    # rubocop:enable Metrics/ParameterLists

    attr_reader :view_context, :text, :id, :icon_class, :open, :title
    delegate :content_tag, :safe_join, :tag, to: :view_context

    def render(&block)
      button_tag + list_tag(&block)
    end

    private

    def button_tag
      tag.a(role: 'button',
            class: "#{button_class}collapse-toggle nav-link",
            data: { toggle: 'collapse' },
            href: "##{id}",
            onclick: "toggleCollapse(this)",
            'aria-expanded' => open,
            'aria-controls' => id,
            title: title) do
        safe_join([tag.span('', class: icon_class, 'aria-hidden': true),
                   tag.span(text)], ' ')
      end
    end

    def list_tag
      tag.ul(class: "collapse #{workflows_class}nav nav-pills nav-stacked",
             id: id) do
        yield
      end
    end

    def button_class
      'collapsed ' unless open
    end

    def workflows_class
      'show ' if open
    end
  end
end
