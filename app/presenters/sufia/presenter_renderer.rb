module Sufia
  class PresenterRenderer
    def initialize(presenter, view_context)
      @presenter = presenter
      @view_context = view_context
    end

    def value(field_name, locals={})
      render_show_field_partial(field_name, locals)
    end

    def label(field_name)
      @view_context.get_label(field_name)
    end

    def fields(terms, &block)
      @view_context.safe_join(terms.map { |term| yield self, term })
    end

    protected

      def render_show_field_partial(field_name, locals)
        partial = find_field_partial(field_name)
        @view_context.render partial, locals.merge(key: field_name, record: @presenter)
      end

      def find_field_partial(field_name)
        ["#{collection_path}/show_fields/_#{field_name}", "records/show_fields/_#{field_name}",
         "#{collection_path}/show_fields/_default", "records/show_fields/_default"].find do |partial|
          Rails.logger.debug "Looking for show field partial #{partial}"
          return partial.sub(/\/_/, '/') if partial_exists?(partial)
        end
      end

      def collection_path
        @collection_path ||= ActiveSupport::Inflector.tableize(@presenter.model_class.model_name)
      end

      def partial_exists?(partial)
        @view_context.lookup_context.find_all(partial).any?
      end
  end
end
