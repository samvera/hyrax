module Hyrax
  module Forms
    module Admin
      class Appearance
        extend ActiveModel::Naming

        def initialize(attributes = {})
          @attributes = attributes
        end

        attr_reader :attributes
        private :attributes

        # This allows this object to route to the correct
        def self.model_name
          ActiveModel::Name.new(self, Hyrax, "Hyrax::Admin::Appearance")
        end

        def to_key
          []
        end

        def persisted?
          true
        end

        def header_background_color
          block_for('header_background_color', '#3c3c3c')
        end

        def header_text_color
          block_for('header_text_color', '#DCDCCE')
        end

        def primary_button_background_color
          block_for('primary_button_background_color', '#286090')
        end

        def primary_button_border_color
          @primary_button_border ||= darken_color(primary_button_background_color, 0.05)
        end

        def primary_button_hover_background_color
          darken_color(primary_button_background_color, 0.1)
        end

        def primary_button_hover_border_color
          darken_color(primary_button_border_color, 0.12)
        end

        def primary_button_active_background_color
          darken_color(primary_button_background_color, 0.1)
        end

        def primary_button_active_border_color
          darken_color(primary_button_border_color, 0.12)
        end

        def primary_button_focus_background_color
          darken_color(primary_button_background_color, 0.1)
        end

        def primary_button_focus_border_color
          darken_color(primary_button_border_color, 0.25)
        end

        def update!
          update_block('header_background_color', attributes[:header_background_color])
          update_block('header_text_color', attributes[:header_text_color])
          update_block('primary_button_background_color', attributes[:primary_button_background_color])
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

          def update_block(name, value)
            ContentBlock.find_or_create_by(name: name).update!(value: value)
          end
      end
    end
  end
end
