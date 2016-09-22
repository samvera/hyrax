module CurationConcerns
  module ChartsHelper
    def hash_to_flot(data)
      data.map { |key, value| { label: key, data: value } }
    end
  end
end
