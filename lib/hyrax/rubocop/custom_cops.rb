# frozen_string_literal: true

require 'rubocop'

module Hyrax
  module RuboCop
    module CustomCops
      # This custom cop checks for mixins of Hyrax::ArResource
      class ArResource < ::RuboCop::Cop::Cop
        MSG = 'Do not `include Hyrax::ArResource`.'

        # checks for `include Hyrax::ArResource`
        def_node_search :includes_hyrax_ar_resource?, <<-PATTERN
          (send nil? {:include :extend} (const (const nil? :Hyrax) :ArResource))
        PATTERN

        # checks for `include ArResource`
        def_node_search :includes_ar_resource?, <<-PATTERN
          (send nil? {:include :extend} (const nil? :ArResource))
        PATTERN

        def on_send(send_node)
          add_offense(send_node, message: MSG) if includes_hyrax_ar_resource?(send_node) || includes_ar_resource?(send_node)
        end
      end

      # class AdditionalCustomCops < ::RuboCop::Cop::Cop; end
    end
  end
end
