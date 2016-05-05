module CurationConcerns
  module Serializers
    def to_s
      if title.present?
        Array.wrap(title).join(' | ')
      elsif label.present?
        Array.wrap(label).join(' | ')
      else
        'No Title'
      end
    end
  end
end
