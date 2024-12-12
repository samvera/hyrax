# frozen_string_literal: true
module Hyrax
  module Forms
    module Admin
      # An object to model and persist the form data for the appearance
      # customization menu
      class Appearance
        extend ActiveModel::Naming

        # @param [Hash] attributes the list of parameters from the form
        def initialize(attributes = {})
          @attributes = attributes
        end

        attr_reader :attributes
        private :attributes

        # This allows this object to route to the correct path
        def self.model_name
          ActiveModel::Name.new(self, Hyrax, "Hyrax::Admin::Appearance")
        end

        # Override this method if your form takes more than just the color_params
        def self.permitted_params
          color_params
        end

        # Required to back a form
        def to_key
          []
        end

        # Required to back a form (for route determination)
        def persisted?
          true
        end

        # The color for the background of the header and footer bars
        def header_background_color
          block_for('header_background_color', '#3c3c3c')
        end

        # The color for the text in the header bar
        def header_text_color
          block_for('header_text_color', '#dcdcdc')
        end

        # The color links
        def link_color
          block_for('link_color', '#104C75')
        end

        # The color for links in the footer
        def footer_link_color
          block_for('footer_link_color', '#ffebcd')
        end

        # The background color for "primary" buttons
        def primary_button_background_color
          block_for('primary_button_background_color', '#286090')
        end

        # The border color for "primary" buttons
        def primary_button_border_color
          @primary_button_border ||= darken_color(primary_button_background_color, 0.05)
        end

        # The mouse over color for "primary" buttons
        def primary_button_hover_background_color
          darken_color(primary_button_background_color, 0.1)
        end

        # The mouse over color for the border of "primary" buttons
        def primary_button_hover_border_color
          darken_color(primary_button_border_color, 0.12)
        end

        # The color for the background of active "primary" buttons
        def primary_button_active_background_color
          darken_color(primary_button_background_color, 0.1)
        end

        # The color for the border of active "primary" buttons
        def primary_button_active_border_color
          darken_color(primary_button_border_color, 0.12)
        end

        # The color for the background of focused "primary" buttons
        def primary_button_focus_background_color
          darken_color(primary_button_background_color, 0.1)
        end

        # The color for the border of focused "primary" buttons
        def primary_button_focus_border_color
          darken_color(primary_button_border_color, 0.25)
        end

        # Persist the form values
        def update!
          self.class.color_params.each do |field|
            update_block(field, attributes[field]) if attributes[field]
          end
        end

        # A list of parameters that are related to custom colors
        def self.color_params
          [:header_background_color,
           :header_text_color,
           :link_color,
           :footer_link_color,
           :primary_button_background_color]
        end

        private

        def darken_color(hex_color, adjustment = 0.2)
          amount = 1.0 - adjustment
          hex_color = hex_color.delete('#')
          rgb = hex_color.scan(/../).map(&:hex)
          rgb[0] = (rgb[0].to_i * amount).round
          rgb[1] = (rgb[1].to_i * amount).round
          rgb[2] = (rgb[2].to_i * amount).round
          format("#%02x%02x%02x", *rgb)
        end

        def block_for(name, default_value)
          block = ContentBlock.find_by(name: name)
          block ? block.value : default_value
        end

        # Persist a key/value tuple as a ContentBlock
        # @param [Symbol] name the identifier for the ContentBlock
        # @param [String] value the value to set
        def update_block(name, value)
          ContentBlock.find_or_create_by(name: name.to_s).update!(value: value)
        end
      end
    end
  end
end
