# frozen_string_literal: true
module Hyrax
  module Serializers
    def to_s
      if title.present?
        title.join(' | ')
      elsif label.present?
        label
      else
        I18n.t('hyrax.works.missing_title')
      end
    end
  end
end
