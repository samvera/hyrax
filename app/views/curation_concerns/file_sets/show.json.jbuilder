json.extract! @file_set, *[:id] + @file_set.class.fields.select {|f| ![:has_model].include? f}
