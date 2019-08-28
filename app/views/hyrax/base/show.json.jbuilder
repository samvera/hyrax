j = json.extract! @curation_concern, *[:id] + @curation_concern.class.fields.reject { |f| [:has_model].include? f }
json.version @curation_concern.etag

if @curation_concern.is_a? Valkyrie::Resource
  j.each do |ele|
    if ele.to_s.include?('_ids')
      json.set! ele, @curation_concern[ele].map(&:id)
    elsif ele.to_s.include?('_id') || ele.to_s == 'id'
      json.set! ele, @curation_concern[ele].id
    end
  end
end
