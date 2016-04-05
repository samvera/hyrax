module CurationConcerns
  module Serializers
    def to_s
      if title.present?
        Array(title).join(' | ')
      elsif label.present?
        Array(label).join(' | ')
      else
        'No Title'
      end
    end
  end
end
