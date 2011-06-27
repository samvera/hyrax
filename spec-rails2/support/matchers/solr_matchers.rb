# Tests whether a solr document has the expected field values set.
# Should work with both Solr::Document and Hash objects
# Ex.
#   @article.to_solr.should have_solr_fields("read_access_group_t"=>"public")
#   @article.to_solr.should_not have_solr_fields("read_access_group_t"=>["public", "registered"])
Spec::Matchers.define :have_solr_fields do |expected|
  match do |actual|
    result = false
    if actual.kind_of?(Hash)
      failures = {}
      expected.each_pair do |field_name, expected_value|
        if actual.has_key?(field_name)
          expected_values = Array(expected_value) 
          if expected_values - actual[field_name] != []
            failures.merge!(field_name => expected_value)
          end
        else
          failures.merge!(field_name => expected_value)
        end
      end
      result =  failures.empty? ? true : false
    elsif actual.kind_of?(Solr::Document)
      inspected = actual.inspect
      result = false
      expected.each_pair do |field_name, field_value|
      /<Solr::Field.*@name=\"#{field_name.to_s}\".*, @value=\"#{field_value}\".*>/
      result = inspected.include?("@name=\"#{field_name.to_s}\", @boost=nil, @value=\"#{field_value}\"") || \
              inspected.include?("@name=\"#{field_name.to_s}\", @value=\"#{field_value}\", @boost=nil") || \
              inspected.include?("@value=\"#{field_value}\", @boost=nil, @name=\"#{field_name.to_s}\"") || \
              inspected.include?("@value=\"#{field_value}\", @name=\"#{field_name.to_s}\", @boost=nil") || \
              inspected.include?("@boost=nil, @value=\"#{field_value}\", @name=\"#{field_name.to_s}\"") || \
              inspected.include?("@boost=nil, @name=\"#{field_name.to_s}\", @value=\"#{field_value}\"")      
      end
     end
     result
  end
  
  failure_message_for_should do |actual|
    msg = ""
    if actual.kind_of?(Hash) 
      expected.each_pair do |field_name, expected_value|
        msg = "expected that the #{field_name} field would contain #{expected_value.inspect}.  Got #{actual[field_name].inspect}"
      end
    else
      msg = "expected that #{expected.keys} would contain a field for #{expected.inspect}"
    end
    msg
  end

  failure_message_for_should_not do |actual|
    msg = ""
    if actual.kind_of?(Hash)    
      expected.each_pair do |field_name, expected_value|
        msg << "expected that the #{field_name} field would not contain #{expected_value.inspect}.  Got #{actual[field_name].inspect}"
      end
    else
      msg = "expected that #{actual.inspect} would not contain a field for #{expected.inspect}"
    end
  end
end