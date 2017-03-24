module Hyrax
  # view-model for the admin menu
  class MenuPresenter
    def initialize(view_context)
      @view_context = view_context
    end

    attr_reader :view_context

    delegate :controller, :controller_name, :action_name, :content_tag,
             :current_page_except_defaults?, :link_to, to: :view_context

    # Returns true if the current controller happens to be one of the controllers that deals
    # with workflow.  This is used to keep the parent section on the sidebar open.
    def workflows_section?
      controller.instance_of? Hyrax::Admin::WorkflowRolesController
    end

    # @param options [Hash, String] a hash or string representing the path. Hash is prefered as it
    #                              allows us to workaround https://github.com/rails/rails/issues/28253
    # @param also_active_for [Hash, String] a hash or string with alternative paths that should be 'active'
    def nav_link(options, also_active_for: nil, **link_html_options)
      active_urls = [options, also_active_for].compact
      list_options = active_urls.any? { |url| current_page_except_defaults?(url) } ? { class: 'active' } : {}
      content_tag(:li, list_options) do
        link_to(options, link_html_options) do
          yield
        end
      end
    end

    # Draw a collaspable menu section. The passed block should contain <li> items.
    def collapsable_section(text, id:, icon_class:, open:, &block)
      CollapsableSectionPresenter.new(view_context: view_context,
                                      text: text,
                                      id: id,
                                      icon_class: icon_class,
                                      open: open).render(&block)
    end
  end
end
