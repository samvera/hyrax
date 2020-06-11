# frozen_string_literal: true
module Hyrax
  class Institution
    def self.name
      I18n.t('hyrax.institution_name')
    end

    def self.name_full
      I18n.t('hyrax.institution_name_full', default: name)
    end
  end
end
