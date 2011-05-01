module Stanford::SearchworksHelper
  
  require_plugin_dependency 'vendor/plugins/blacklight/app/helpers/application_helper.rb'
  
  include Stanford::SolrHelper  # for nearby on shelf lookups
    
  # def application_name
  #   'SearchWorks (SULAIR)'
  # end
  def vern_document_heading
    @document[Blacklight.config[:show][:vern_heading]]
  end
  def home_facet_field_names
    Blacklight.config[:home_facet][:solr]
  end
  def home_facet_field_labels
    Blacklight.config[:home_facet][:labels]
  end
  # overriding because we need to escape the '< Previous' at the linking level
  def link_to_previous_document(previous_document)
    return if previous_document == nil
    link_to_document previous_document, :label=>'&laquo; Previous', :counter => session[:search][:counter].to_i - 1
  end
  # overriding because we need to escape the 'Next >' at the linking level
  def link_to_next_document(next_document)
    return if next_document == nil
    link_to_document next_document, :label=>'Next &raquo;', :counter => session[:search][:counter].to_i + 1
  end

  # copies the current params (or whatever is passed in as the 3rd arg)
  # removes the field value from params[:f]
  # removes the field if there are no more values in params[:f][field]
  # removes additional params (page, id, etc..)
  def remove_query_params(value, source_params=params)
    p = source_params.dup.symbolize_keys!
    # need to dup the facet values too,
    # if the values aren't dup'd, then the values
    # from the session will get remove in the show view...
    p[:q] = p[:q].dup
    p.delete :page
    p.delete :id
    p.delete :total
    p.delete :counter
    p.delete :commit
    #return p unless p[field]
    p[:q] = p[:q].gsub(value,"").strip
    p.delete(:q) if p[:q].size == 0
    p
  end
  
  # link_back_to_catalog(:label=>'Back to Search')
  # Create a link back to the index screen, keeping the user's facet, query and paging choices intact by using session.
  def link_back_to_catalog(opts={:label=>'Back to Search'})
    query_params = session[:search].dup || {}
    query_params.delete :counter
    query_params.delete :total
    link_url = root_path(query_params)
    link_to opts[:label], link_url
  end
  
  # This is an updated +link_to+ that allows you to pass a +data+ hash along with the +html_options+
  # which are then written to the generated form for non-GET requests. The key is the form element name
  # and the value is the value:
  #
  #  link_to_with_data('Name', some_path(some_id), :method => :post, :html)
  def link_to_with_data(*args, &block)
    if block_given?
      options      = args.first || {}
      html_options = args.second
      concat(link_to(capture(&block), options, html_options))
    else
      name         = args.first
      options      = args.second || {}
      html_options = args.third

      url = url_for(options)

      if html_options
        html_options = html_options.stringify_keys
        href = html_options['href']
        convert_options_to_javascript_with_data!(html_options, url)
        tag_options = tag_options(html_options)
      else
        tag_options = nil
      end

      href_attr = "href=\"#{url}\"" unless href
      "<a #{href_attr}#{tag_options}>#{name || url}</a>"
    end
  end
  # Generate the # - # of # results text
  def results_text(pp, p, result_num)
    if pp.nil?
      per_page = Blacklight.config[:index][:num_per_page].to_i
    else
      per_page = pp.to_i     
    end
    
    if p.nil?
      start_num = 1
      p = 1
    else
      start_num = (p.to_i * per_page) - (per_page - 1)
    end
    
    if p == 1 and per_page < result_num
      end_num = per_page
    elsif ((per_page * p.to_i) > result_num)
      end_num = result_num
    else
      end_num = per_page * p.to_i
    end
    "#{start_num} - #{end_num} of "
  end
  # Genrate dt/dd with a relevance
  def get_relevance_bar(score,label)
    score_mod = (score * 9).round(2)
    if score_mod > 100
      score_mod = 100
    elsif score_mod == 0.0
      score_mod = (score * 9).round(4)
    end
    text =  "<dt>#{label}</dt>"
    text += "<dd>"
      text += "<div class='relevance_container'>"
        text += "<span>#{score_mod}%</span>"
        text += "<div class='relevance_bar' style='width:#{score_mod}%'>"
        text += "</div>"
      text += "</div>"
    text += "</dd>"
  end
  
  # Generate a dt/dd pair given a Solr field
  # If you provide a :default value in the opts hash, 
  # then when the solr field is empty, the default value will be used.
  # If you don't provide a default value, this method will not generate html when the field is empty.
  def get_data_with_label(doc, label, field_string, opts={})
    if opts[:default] && !doc[field_string]
      doc[field_string] = opts[:default]
    end
    
    if doc[field_string]
      field = doc[field_string]
      text = "<dt>#{label}</dt><dd>"
      if field.is_a?(Array)
          field.each do |l|
            text += "#{h(l)}"
            if l != h(field.last)
              text += "<br/>"
            end
          end
      else
        text += h(field)
      end
      #Does the field have a vernacular equivalent? 
      if doc["vern_#{field_string}"]
        vern_field = doc["vern_#{field_string}"]
        text += "<br/>"
        if vern_field.is_a?(Array)
          vern_field.each do |l|
            text += "#{h(l)}"
            if l != h(vern_field.last)
              text += "<br/>"
            end
          end
        else
          text += h(vern_field)
        end
      end
      text += "</dd>"
      text
    end
  end
  # generate an dt/dd pair given a marc field
  def get_data_with_label_from_marc(doc,label,field,sFields=[])
    if doc.marc[field]
      text = "<dt>#{label}</dt><dd>"
      doc.marc.find_all{|f| (field) === f.tag}.each do |l|
      if sFields.length > 0
        l.each{|sl| sFields.include?(sl.code) ? text << "#{h(sl.value)} " : ""}
      else
        temp_text = ""
        # get_vern method should be here? In each loop below? After?
        l.each {|sl| ['w','0', '5', '6', '8'].include?(sl.code) ? nil : temp_text += "#{sl.value} "}
        vernacular = get_vernacular(doc,l)
        text += h(temp_text)
      end
        vernacular = get_vernacular(doc,l)
        text += "<br/>#{vernacular}" unless vernacular.nil?
        text += "<br/>" unless l == doc.marc.find_all{|f| (field) === f.tag}.last
      end
      text += "</dd>"
      text
    else
      
      # The below if statement is attempting to find unmatched vernacular fields that match the supplied field string
      if doc.marc['880']
        doc.marc.find_all{|f| ('880') === f.tag}.each do |l|
          if l['6'].split("-")[1].gsub("//r","") == "00" and l['6'].split("-")[0] == field
            text = "<dt>#{label}</dt><dd>"
              l.each {|sl| ['w','0', '5', '6', '8'].include?(sl.code) ? nil : text += "#{sl.value} "}
            text += "</dd>"
          end
        end
        text
      end
      
    end
  end
  # Generate a dt/dd pair with a comma separated list of formats given an array of format strings
  def show_formats(field)
    if field
      text = "<dt>Format:</dt><dd>"
      field.each do |l|
        text += "<span class='iconSpan #{l.downcase.gsub(" ","").gsub("/","_")}'>"
          text += h(l)
          text += ", " unless l == field.last
        text += "</span>"
      end
      text += "</dd>"
      text
    end
    
    
  end
  # Generate a dt/dd pair with a link with a label given a field in the SolrDocument
  def link_to_data_with_label(doc,label,field_string,url)
    if doc[field_string]
      field = doc[field_string]
      text = "<dt>#{label}</dt><dd>"
      if field.is_a?(Array)
        field.each do |l|
          text += link_to l, url.merge!(:q => "\"#{l}\"")
          if l != field.last
            text += "<br/>"
          end
        end
      else
        text += link_to field, url.merge!(:q => "\"#{field}\"")
      end
      if doc["vern_#{field_string}"]
        vern_field = doc["vern_#{field_string}"]
        text += "<br/>"
        if vern_field.is_a?(Array)
          vern_field.each do |l|
            text += link_to l, url.merge!(:q => "\"#{l}\"")
            if l != vern_field.last
              text += "<br/>"
            end
          end
        else
          text += link_to vern_field, url.merge!(:q => "\"#{vern_field}\"")
        end
      end
      
      text += "</dd>"
      text
    end
  end
  # Generate dt/dd pair with an unordered list from the table of contents (IE marc 505s)
  def get_toc(doc)
    if doc.marc['505']
      text = "<dt>Contents:</dt><dd>"
      doc.marc.find_all{|f| ('505') === f.tag}.each do |l|
        text << "<ul class='toc'><li>"
        l.each{|sl| ['w','0', '5', '6', '8'].include?(sl.code) ? nil : text << "#{sl.value.gsub(' -- ','</li><li>')} " }
        text << "</li></ul>"
        text << "<ul class='toc'><li>#{get_vernacular(doc,l).gsub('--','</li><li>')}</li></ul>" unless get_vernacular(doc,l).nil?
      end
      text << "</dd>"
    else
      if doc.marc['880']
        doc.marc.find_all{|f| ('880') === f.tag}.each do |l|
          if l['6'].split("-")[1].gsub("//r","") == "00" and l['6'].split("-")[0] == "505"
            text = "<dt>Contents:</dt><dd><ul class='toc'><li>"
              l.each {|sl| ['w','0', '5', '6', '8'].include?(sl.code) ? nil : text << "#{sl.value.gsub('--','</li><li>')} "}
            text << "</li></dd>"
          end
        end
        text
      end
    end
  end
  # Generate dt/dd pair with a link with a label given a marc field
  def link_to_data_with_label_from_marc(doc,label,field,url,sFields=[])
    if doc.marc[field]
      text = "<dt>#{label}</dt><dd>"
      doc.marc.find_all{|f| (field) === f.tag}.each do |l|
        if sFields.length > 0
          link_text = ""
          sFields.each do |sf|
            if l.find{|s| s.code == sf.to_s}
              link_text << "#{l.find{|s| s.code == sf.to_s}.value} "
            end
          end
          text += link_to link_text, url.merge!(:q => "\"#{link_text}\"")
        else
          link_text = ''
          l.each {|sl| ['w','0', '5', '6', '8'].include?(sl.code) ? nil : link_text += "#{sl.value} " unless (sl.code == 'a' and sl.value[0,1] == "%") }
          text += link_to link_text, url.merge!(:q => "\"#{link_text}\"")
        end
        vernacular = get_vernacular(doc,l)
        temp_vern = "\"#{vernacular}\""
        text += "<br/>#{link_to vernacular, url.merge!(:q => temp_vern)}" unless vernacular.nil?
        text += "<br/>" unless l == doc.marc.find_all{|f| (field) === f.tag}.last
      end
      text += "</dd>"
    else
      if doc.marc['880']
        doc.marc.find_all{|f| ('880') === f.tag}.each do |l|
          if l['6'].split("-")[1].gsub("//r","") == "00" and l['6'].split("-")[0] == field
            text = "<dt>#{label}</dt><dd>"
              link_text = ''
              l.each {|sl| ['w','0', '5', '6', '8'].include?(sl.code) ? nil : link_text += "#{sl.value} "}
              text += link_to link_text, url.merge!(:q => "\"#{link_text}\"")
            text += "</dd>"
          end
        end
        text
      end
    end
  end
  # Generate dt/dd pair of contributors with translations
  def link_to_contributor_from_marc(doc)
    text = "<dt>Contributor:</dt><dd>"
    ['700', '710', '711', '720'].each do |field|
      if doc.marc[field]
        doc.marc.find_all{|f| (field) === f.tag}.each do |l|
          link_text = ''
          relator_text = []
          l.each {|sl| sl.code == '4' ? relator_text << " #{relator_terms[sl.value]}" : sl.code == '6' ? nil : link_text << "#{sl.value} "}
          text << link_to(link_text.strip, :q => "\"#{link_text}\"", :controller => 'catalog', :action => 'index', :qt => 'search_author' )
          text << relator_text.join(", ") unless relator_text.empty?
          vernacular = get_vernacular(doc,l)
          temp_vern = "\"#{vernacular}\""
          text << "<br/>#{link_to vernacular, :q => temp_vern, :controller => 'catalog', :action => 'index', :qt => 'search_author'}" unless vernacular.nil?
          text << "<br/>"
        end
      else
        if doc.marc['880']
          doc.marc.find_all{|f| ('880') === f.tag}.each do |l|
            if l['6'].split("-")[1].gsub("//r","") == "00" and l['6'].split("-")[0] == field
              text = "<dt>Contributor:</dt><dd>"
                link_text = ''
                relator_text = []
                l.each {|sl| sl.code == '4' ? relator_text << " #{relator_terms[sl.value]}" : link_text << "#{sl.value} "}
                text << link_to(link_text.strip,:q => "\"#{link_text}\"", :action => 'index', :qt => 'author_search')
                text << relator_text.join(", ") unless relator_text.empty?
            end
          end
        end
      end
    end
    text << "</dd>"
    text unless text == "<dt>Contributor:</dt><dd></dd>"
  end
  
  def title_change_data_from_marc(doc)
    if doc.marc['780'] or doc.marc['785']
      text = ""

      if doc.marc['780']
        doc.marc.find_all{|f| ('780') === f.tag}.each do |field|
          text << "<dt>#{name_change_780_translations[field.indicator2]}:</dt>"
          temp_text = ""
          field.each{|subfield|
            if subfield.code == "w"
              nil
            elsif subfield.code == "t"
              query = "\"#{subfield.value}\""
              temp_text << "#{link_to(subfield.value, params.dup.merge!(:action=>'index', :qt=>'search_title', :q=>query))} "
            elsif subfield.code == "x"
              temp_text << "(#{link_to(subfield.value, params.dup.merge!(:action=>'index', :qt=>'search', :q=>subfield.value))}) "
            else
              temp_text << "#{subfield.value} "
            end
          }
          text << "<dd>#{temp_text}</dd>"
        end
      end

      if doc.marc['785']
        special_handler = []
        doc.marc.find_all{|f| ('785') === f.tag}.each do |field|
          if field.indicator2 == "7"
            special_handler << field
          end
        end
        
        doc.marc.find_all{|f| ('785') === f.tag}.each do |field|
          text << "<dt>"
          if field.indicator2 == "7" and field == special_handler.first
            text << "Merged with:"
          elsif field.indicator2 == "7" and field == special_handler.last
            text << "to form:"
          elsif field.indicator2 == "7" and field != special_handler.first and field != special_handler.last
            text << "and with:"
          else
            text << "#{name_change_785_translations[field.indicator2]}:"
          end
          text << "</dt>"
          temp_text = ""
          field.each{|subfield|
            if subfield.code == "w"
              nil
            elsif subfield.code == "t"
              query = "\"#{subfield.value}\""
              temp_text << "#{link_to(subfield.value, params.dup.merge!(:action=>'index', :qt=>'search_title', :q=>query))} "
            elsif subfield.code == "x"
              temp_text << "(#{link_to(subfield.value, params.dup.merge!(:action=>'index', :qt=>'search', :q=>subfield.value))}) "
            else
              temp_text << "#{subfield.value} "
            end
          }
          text << "<dd>#{temp_text}</dd>"
        end
      end
      text
    end
  end
  
  
  # Generate hierarchical structure of subject headings from marc
  def get_subjects(doc)
    text = "<ul id='related_subjects'>"
    subs = ['600','610','611','630','650','651','653','654','655','656','657','658','690','691','693','696', '697','698','699']
    data = []
    subs.each do |s|
      if doc.marc[s]
        doc.marc.find_all{|f| (s) === f.tag }.each do |l|
          multi_a = []
          temp_data_array = []
          temp_subs_text = ""
          temp_xyv_array = []
          unless (s == "690" and l['a'].downcase.include?("collection"))
            l.each{|sf| 
              unless ['w','0', '1', '2', '3', '4', '5', '6', '7', '8', '9'].include?(sf.code) 
                if sf.code == "a"
                  multi_a << sf.value unless sf.code == "a" and sf.value[0,1] == "%"
                end
                if ["v","x","y","z"].include?(sf.code)
                  temp_xyv_array << sf.value
                else
                  temp_subs_text << "#{sf.value} " unless (sf.code == "a" or (sf.code == "a" and sf.value[0,1] == "%"))
                end
              end
            }
            if multi_a.length > 1
              multi_a.each do |a|
                data << [a]
              end
            elsif multi_a.length == 1
              str = multi_a.to_s << " " << temp_subs_text unless (temp_subs_text.blank? and multi_a.empty?)
              temp_data_array << str
            else
              temp_data_array << temp_subs_text unless temp_subs_text.blank?
            end
            temp_data_array.concat(temp_xyv_array) unless temp_xyv_array.empty?
            data << temp_data_array unless temp_data_array.empty?
          end
        end
      end
    end
    i = 0
   
    data.each do |fields|
      text << "<li>"
      link_text = ""
      title_text = "Search: "
      fields.each do |field|
        link_text << " " unless field == data[i].first
        link_text << "\"#{field.strip}\""
        title_text <<  " - " unless field == data[i].first
        title_text << "#{field.strip}"
        text << link_to(field.strip, {:controller => 'catalog', :action => 'index', :q => link_text, :qt => 'search_subject'}, :title => title_text)
        text << " &gt; " unless field == data[i].last
      end
      text << "</li>"
      i += 1
    end
    text << "</ul>"
    return text unless text == "<ul id='related_subjects'></ul>"
  end
  # Generate unordered list of Online Access Links (IE marc 856s)
  def get_856(doc)
    if doc.marc['856']
      text = ''
      int = 1
      text += "<ul class='online'>"
        text += "<li>"
          text += "<ol>"
            doc.marc.find_all{|f| ('856') === f.tag }.each do |field|
              if !field['u'].nil?
                # Not sure why I need this, but it fails on certain URLs w/o it.  The link printed still has character in it
                fixed_url = field['u'].gsub("^","").strip
                url = URI.parse(fixed_url)
                sub3 = ""
                subz = []
                suby = ""
                field.each{|subfield| 
                  if subfield.code == "3"
                    sub3 = subfield.value
                  elsif subfield.code == "z"
                    subz << subfield.value
                  elsif subfield.code == "y"
                    suby = subfield.value
                  end
                }
                if int > 3
                  text += "<li class='more' style='display:none;'>#{!sub3.blank? ? sub3 << ' ' : ''}#{!subz[0].blank? ? subz[0] << ' ' : ''}<a href='#{field['u']}'>#{(subz[1] and field['x'] == "eLoaderURL") ? subz[1] : !suby.blank? ? suby : url.host}</a></li>"
                else
                  text += "<li>#{!sub3.blank? ? sub3 << ' ' : ''}#{!subz[0].blank? ? subz[0] << ' ' : ''}<a href='#{field['u']}'>#{(subz[1] and field['x'] == "eLoaderURL") ? subz[1] : !suby.blank? ? suby : url.host}</a></li>"
                end
                if int == 3 and field != doc.marc.find_all{|f| ('856') === f.tag }.last
                  text += "<li class='more_link' id='more_link'><a href=''>more<span class='off_screen'> links</span></a></li>"
                end
                int += 1
              end
            end
            if int > 3 
              text += "<li id='less_link' class='less_link' style='display:none;'><a href=''>less<span class='off_screen'> links</span></a></li>"
            end
          text += "</ol>"
        text += "</li>"
      text += "</ul>"
      text
    end
  end
  
  def get_suppl_urls(doc)
    text = ""
    if doc['url_fulltext']
      urls = doc['url_fulltext']
      text << "<dt>Online:</dt><dd>"
      #urls.each do |url|
        fixed_url = urls[0].gsub("^","").strip
        url_host = URI.parse(fixed_url).host
        text << "<a href='#{urls[0].strip}'>#{url_host}</a>"
        if urls.length > 1
          text << " + #{pluralize(urls.length - 1, 'more source')}"
        end
      #end
      text << "</dd>"
    end
    text
    
  rescue URI::InvalidURIError
    return ""
  end
  
  def get_vernacular(doc,field)
    return_text = ""
    if field['6']
      field_original = field.tag
      match_original = field['6'].split("-")[1]
      doc.marc.find_all{|f| ('880') === f.tag}.each do |l|
        if l['6']
          field_880 = l['6'].split("-")[0]
          match_880 = l['6'].split("-")[1].gsub("//r","")
          if match_original == match_880 and field_original == field_880
            return_text = ""
            l.each{
              |sl| 
              if !['w','0', '5', '6', '8'].include?(sl.code)
                return_text += "#{sl.value} "
              end
            }
          end
        end
      end
    end
    return nil if return_text.blank?
    return_text
  end
  
  def get_callnum(doc)
    test_hash = {}
    if doc['item_display']
      doc['item_display'].each do |item|
        item_array = item.split(' -|- ')
        if test_hash.has_key?(item_array[1])
          if test_hash[item_array[1]].has_key?(item_array[2])
            if params[:action] == 'index'
              test_hash[item_array[1]][item_array[2]] << [item_array[3],item_array[0],item_array[6],item_array[4],item_array[7]] unless test_hash[item_array[1]][item_array[2]].flatten.include?(item_array[3])
            else
              test_hash[item_array[1]][item_array[2]] << [item_array[3],item_array[0],item_array[6],item_array[4],item_array[7]] #|Commenting out so that multiple copies show up on record view| unless test_hash[item_array[1]][item_array[2]].flatten.include?(item_array[6])
            end
          else
            test_hash[item_array[1]][item_array[2]] = [[item_array[3],item_array[0],item_array[6],item_array[4],item_array[7]]]
          end
        else
          test_hash[item_array[1]] = {item_array[2] => [[item_array[3],item_array[0],item_array[6],item_array[4],item_array[7]]]}
        end
      end
    end
    test_hash
  end
  
  def get_facet_tag_cloud(facet,response)
    text = ""
    display_facet = response.facets.detect {|f| f.name == facet }
    facet_arr = []
    display_facet.items.each do |item| 
      facet_arr << [item.hits,item.value]
    end
    facet_arr = facet_arr.sort_by {rand}
    text += "<div class='cloud_div' id='cloud_#{facet}'>"
    facet_arr.each do |l|
      if l[0] > 500000
        #font_size = "3"
        font_size = "jumbo"
      elsif l[0] > 100000
        #font_size = "2.2"
        font_size = "large"
      elsif l[0] > 75000
        #font_size = "1.8"
        font_size = "medium"
      elsif l[0] > 50000
        #font_size = "1.4"
        font_size = "small"
      else
        #font_size = "1"
        font_size = "tiny"
      end
      if facet == 'building_facet' and translate_lib.has_key?(l[1])
        value = translate_lib[l[1]]
      else
        value = l[1]
      end
      text +=  " <span class='tag_cloud #{font_size}'>#{link_to h(value), add_facet_params(facet, l[1])}</span> "
    end
    text += "</div>"
  end
  
  # given the solr field name of a *refinement* facet (e.g. lc_alpha_facet),
  # return a string containing appropriate html to display the given facet
  # heading and its values
  def get_refine_facet(solr_fname, response)
    text = ""
    display_facet = response.facets.detect {|f| f.name == solr_fname} 
    if !display_facet.nil? && !display_facet.items.nil? && display_facet.items.length > 0
      text = "<li>"
      text << " <h3 class='facet_selected'>" + facet_field_labels[solr_fname] + "</h3>"
      text << " <ul>"
      item_count = 0
      display_facet.items.each do |item|
        if facet_in_params? solr_fname, item.value
          text << "<li>"
          text << "<span class='selected'>" + h(item.value) + " (" + item.hits.to_s + ")</span>"
          text << "[#{link_to 'remove', remove_facet_params(solr_fname, item.value), :class=>'remove'}]"
          text << "</li>"
          # accommodate further call number levels
          case solr_fname
            when "lc_alpha_facet"
              text << get_refine_facet("lc_b4cutter_facet", response)
            when "dewey_2digit_facet"
              text << get_refine_facet("dewey_b4cutter_facet", response)
            when "dewey_1digit_facet"
              text << get_refine_facet("dewey_2digit_facet", response)
          end
        else
          # display the value as a link unless it is at the peer level of a selected call number facet -%>
          if !( display_facet.name.match(/^(lc_|dewey_|gov_)/i) && params_facet_has_value?(display_facet.name) ) 
            if item_count > 4
              text << "   <li class=\"more\">"
            else
              text << "   <li>"
            end
            if params[:qt] == 'standard'
              text << "     #{h(item.value)} (" + item.hits.to_s + ")"
            else
              text << "     #{link_to h(item.value), add_facet_params(solr_fname, item.value)} (" + item.hits.to_s + ")"
            end
            text << "   </li>"
            item_count += 1
          end
        end
      end
      if display_facet.items.length > 5
        if !( display_facet.name.match(/^(lc_|dewey_|gov_)/i) && params_facet_has_value?(display_facet.name) ) 
          text << "<li class='more_li'><a href='' class='more_link' alt='more' #{home_facet_field_labels[solr_fname]}>more...</a></li>"
          text << "<li class='less_li' style='display:none;'><a href='' class='more_link' alt='less' #{home_facet_field_labels[solr_fname]}>less...</a></li>"
        end
      end
      text << " </ul>"
      text << "</li>"
    end # have facet to display
    text
  end
  
  # true or false, depending on whether the field and a value is in params[:f]
  def params_facet_has_value?(field)
    if params[:f] and params[:f][field]
     !params[:f][field].compact.empty? 
    else
      false
    end
  end
  
  
  def get_search_breadcrumb_terms(q_param)
    if q_param.scan(/"([^"\r\n]*)"/)
      q_arr = []
      old_q = q_param.dup
      q_param.scan(/"([^"\r\n]*)"/).each{|t| q_arr << "\"#{h(t)}\""}
      q_arr.each do |l|
        old_q.gsub!(l,'')
      end
      unless old_q.blank?
        old_q.split(' ').each {|q| q_arr << h(q) }
      end
    q_arr
    else
       q_arr = q_param.split(' ')
    end
  end
  
  def get_advanced_search_query_terms(params)    
    # if using the standard query parser and have an actual query we need to modify the q param after the search results are requested to something more visually friendly
    if params[:qt] == "standard" and params[:q] != "collection:sirsi"
      str = []
      fields = []
      new_query = params[:q][1,params[:q].length-2]
      new_query.gsub!(") AND (", " -|- ")
      new_query.gsub!(") OR (", " -|- ")
      new_query.gsub!(/\^\d+ OR /, " -|- ")
      new_query.split(" -|- ").each do |query_string|
        fields << query_string.split(":")[0]
        query = query_string.split(":")[1][/\(.*\)/]
        Blacklight.config[:advanced].each do |key,value|
          if value.keys.collect{|x| x.to_s}.sort == fields.sort
            str << "#{key.to_s == "description_checked" ? "Description-TOC" : key.to_s.capitalize} = #{query[1,query.length][0,query.length-2]}" unless str.include?("#{key.to_s == "description_checked" ? "Description-TOC" : key.to_s.capitalize} = #{query[1,query.length][0,query.length-2]}")
            fields = []
          end
        end
      end
      h str.join(" #{params[:op]} ")
    end
  end
  
  def get_advanced_search_filter_terms(params)
    # Modifying the fq param to be what the UI is expecting from the f param, then setting the f param to this modified hash
    # Note that the query to Solr has already been made, anything beyond this will just be modifying how the UI interperets the query
    unless params[:fq].to_s.empty?
      a_hash = {}
      fq_params = params[:fq].split("), ")
      fq_params.each do |fq_param|
        fq_fields = fq_param.split(":")
        fq_field = fq_fields[0]
        fq_values = fq_fields[1][1,fq_fields[1].length][0,fq_fields[1].length-2].split('" OR "')
        fq_values.each do |value|
          if a_hash.has_key?("#{fq_field}")
            a_hash["#{fq_field}"] << value.gsub('"',"")
          else
            a_hash["#{fq_field}"] = [value.gsub('"',"")]
          end
        end
      end
      a_hash
    end
  end
  
  def previous_search_is_referrer?
    # If the referrer params are empty and there is no search history return false (User went directly to the record w/o a search session)
    if referrer_params.empty? and url_back_to_catalog.empty?
      false
    # If  the search history == the referrer params return true.
    elsif url_back_to_catalog == referrer_params
      true
    # If the referrer includes the base URL (ie, <Prev | Next> links on record view) then return true
    elsif request.referrer.include?(url_for({:controller => 'catalog', :only_path => false}))
      true
    else
      false
    end
  end
  
  def referrer_params
    request_params = {}
    if request.referrer.to_s.include?("&") or request.referrer.to_s.include?("?") 
      request.referrer.to_s[/\/\?.*/].split("&").each do |paramater|
        unless paramater == "/?"
          key = CGI::unescape(paramater.split("=")[0].gsub(/\/\?/,"")).to_sym
          key.to_s[0,2] == "/?" ? key.to_s.gsub!("/?","").to_sym : ""
          value = paramater.split("=").length > 1 ? h(paramater.split("=")[1].gsub("+"," ")) : ""
          if request_params.has_key?(key)
            request_params[key] << CGI::unescape(value)
          else
            request_params[key] = CGI::unescape(value)
          end
        end
      end
    end
    request_params
  end
  
  # url back to catalog
  # show the url back to the search result, keeping the user's facet, query and paging choices intact by using session.
  # this is to match against the http.referrer
  def url_back_to_catalog
    query_params = session[:search].dup || {}
    query_params.delete :counter
    query_params.delete :total
    if query_params.has_key?(:f)
      query_params[:f].each do |key,val|
        query_params["f[#{key}][]".to_sym] = val.to_s
      end
      query_params.delete(:f)
    end
    query_params
  end
  
  
  # Generate display text for "nearby" selections according to call number
  def get_nearby_items(document, response, how_many)
    text = "<ul id='nearby_objects'>"

# TODO:  how choose if there are multiple call numbers for this document?
#   1.  VALID call numbers only
#   2.  if only one, use it
#   3.  if only one LC, use it
#   4.  if multiple LC, do someting
#   5.  if no LC, do something
    
    if !document[:callnum_sort].nil?
=begin    
      num = document[:callnum_sort].length
      if num == 1
        this_item_shelfkey = document[:callnum_sort][0].downcase
      elsif 
        # only one LC, use it
      elsif
        # mult LC, use ... one of them?
      else
        # no LC ... do something
        
      end
=end

#puts('DEBUG: document has callnum_sort ' + document[:callnum_sort].to_s)
      this_item_shelfkey = document[:callnum_sort][0].downcase
#      this_item_reverse_shelfkey = reverse_alphanum(this_item_shelfkey)
# FIXME:  don't have the right conversion yet ..
      this_item_reverse_shelfkey = document[:callnum_reverse_sort][0].downcase

# TODO: need to take all the returned <li> and sort them by shelfkey, then by title, then by author

      # get preceding bookspines
      
      # terms is array of one element hashes with key=term and value=count
      terms_array = get_next_terms(this_item_reverse_shelfkey, "callnum_reverse_sort", how_many+1)
      reverse_shelfkeys_b4 = []
      num_docs = 0
puts "num rev terms is " + terms_array.length.to_s
      terms_array.each { |term_hash|
        reverse_shelfkeys_b4 << term_hash.keys[0] unless term_hash.keys[0] == this_item_reverse_shelfkey
        num_docs = num_docs + term_hash.values[0]
      }
      text << get_spines_from_field(reverse_shelfkeys_b4, "callnum_reverse_sort").join

=begin          
      #  preceding shelfkeys are in the reverse order of what we need to display -
      #   they are returned as closest, next closest, ... , furthest
      #   but b/c they are displayed BEFORE the current result, they 
      #   need to be ordered furthest to closest
      # also, don't display THIS document's stuff yet.
#      reverse_shelfkeys_b4.reverse_each do |r_shelfkey|
      reverse_shelfkeys_b4.each do |r_shelfkey|
        if r_shelfkey != reverse_shelfkeys_b4.first
#          text << get_spines_from_field(reverse_shelfkeys_b4, "callnum_reverse_sort").join
          text << get_spines_from_field([r_shelfkey], "callnum_reverse_sort").join
        end
      end
=end
    
      # display spine for THIS doc's shelfkey
      text << "<br/>"
      if terms_array[0].values[0] == 1
        # orig document is only instance of its shelfkey
        spines = get_spines_from_doc(document, [this_item_shelfkey])
        unless spines.nil?
          spines.each { |spine|  
            text << spine unless text.include?(spine)
          }
        end
      else
        text << get_spines_from_field([this_item_shelfkey], "callnum_sort").join
      end      
      text << "<br/>"

      # get following bookspines
      terms_array = get_next_terms(this_item_shelfkey, "callnum_sort", how_many+1)
      shelfkeys_after = []
      num_docs = 0
puts "num terms is " + terms_array.length.to_s
      terms_array.each { |term_hash|  
        shelfkeys_after << term_hash.keys[0] unless term_hash.keys[0] == this_item_shelfkey
        num_docs = num_docs + term_hash.values[0]
      }
      
      text << get_spines_from_field(shelfkeys_after, "callnum_sort").join
      
=begin      
      shelfkeys_after.each do |shelfkey|
        if shelfkey != shelfkeys_after.first
#          text << get_spines_from_field(shelfkeys_after, "callnum_sort").join
          text << get_spines_from_field(shelfkey[0], "callnum_sort").join
        end
      end
=end
    end
    
    text << "</ul>"
    return text unless text == "<ul id='nearby_objects'><br/><br/></ul>"
  end
  
  
  protected
  # create an array of sorted html list items containing the appropriate display text
  #  (analogous to what would be visible if you were looking at the spine of 
  #  a book on a shelf) from relevant solr docs, given a particular solr
  #  field and value for which to retrieve spine info.
  # The shelf key in each html list item must match a desired shelf key in the
  # desired_shelfkeys array
  def get_spines_from_field(values, field)

# FIXME:  I think we want to deal with reversing and the like in the calling
#  method.  This should get spines given a particular list of shelf keys
    # in each doc, we look for item display matches for shelfkeys, not reverse shelfkeys
    desired_shelfkeys = []
    if (field == "callnum_reverse_sort")
      values.each { |rev_shelfkey|  
        # turn it back into a shelfkey
        desired_shelfkeys << reverse_alphanum(rev_shelfkey)
      }
    else
      desired_shelfkeys = values
    end

    unsorted_result = []
    docs = get_docs_for_field_values(values, field)
    docs.each do |doc|
# FIXME!!!  "desired_shelfkeys" is call numbers, but we have shelfkeys ...
      unsorted_result = unsorted_result | get_spines_from_doc(doc, desired_shelfkeys)
    end
    unsorted_result.uniq!
    # result is:   title [(pub year)] [<br/> author] <br/> callnum
    
    # need to sort results by callnum asc, then by title asc, then by pub date desc
    sort_hash = {}
    unsorted_result.each_index { |i|
      line_array = unsorted_result[i].split("<br/>")
      callnum = line_array.last
      # need to get rid of <li> and link stuff 
      title_year = line_array.first.sub(/<li>.*<a.*">/, '')
      title = title_year.sub(/\(\d.*\)/, '')
      year = title_year.sub(/.*\(/, '')
      sort_hash[i]= callnum + ' ' + title + ' ' + reverse_alphanum(year)
    }
    # sort by values, then order result (then lift and separate?)
    sorted_array = sort_hash.sort { |a,b| a[1] <=> b[1]}
    sorted_result = []
    sorted_array.each_index { |i|
      # sort_array is array of [unsorted_result_ix, sort_val]
      sort_ix = sorted_array[i][0]
      sorted_result[i]= unsorted_result[sorted_array[i][0]]
    }
    
    sorted_result
  end

  # create an array of html list items containing the appropriate display text
  #  (analogous to what would be visible if you were looking at the spine of 
  #  a book on a shelf) from a solr doc.  
  # The shelf key in each html list item must match a desired shelf key in the
  # desired_shelfkeys array
  def get_spines_from_doc(doc, desired_shelfkeys, max_len=30)
    result = []
    return if doc[:item_display].nil?
    doc[:item_display].each { |item_disp|  
      callnum = item_disp.split(" -|- ")[3]
#      if desired_shelfkeys.include?(callnum)
      if true
        id = doc[:id]
        title = doc[:title_245a_display]
        author = case 
          when doc[:author_person_display] : doc[:author_person_display]
          when doc[:author_corp_display] : doc[:author_corp_display]
          when doc[:author_meeting_display] : doc[:author_meeting_display]
          else nil
        end
        pub_year = doc[:pub_date]

        spine_text = "<li>"
        spine_text << link_to_document(doc, :label=>title[0,max_len])
        spine_text << " (" + pub_year + ")" unless pub_year.nil? || pub_year.length == 0
        spine_text << "<br/>" + author[0,max_len] unless author.nil?
        spine_text << "<br/>" + callnum
        spine_text << "</li>"
        result << spine_text unless result.include?(spine_text)
      end
    }
    return result
  end

  def reverse_alphanum(str)
    rev_str = String.new(str)
    last = str.length-1
    for i in 0..last
      case rev_str[i,1]
        when '~': rev_str[i]= ' '
        when '0': rev_str[i]= 'z'
        when '1': rev_str[i]= 'y'
        when '2': rev_str[i]= 'x'
        when '3': rev_str[i]= 'w'
        when '4': rev_str[i]= 'v'
        when '5': rev_str[i]= 'u'
        when '6': rev_str[i]= 't'
        when '7': rev_str[i]= 's'
        when '8': rev_str[i]= 'r'
        when '9': rev_str[i]= 'q'
        when 'a': rev_str[i]= 'p'
        when 'b': rev_str[i]= 'o'
        when 'c': rev_str[i]= 'n'
        when 'd': rev_str[i]= 'm'
        when 'e': rev_str[i]= 'l'
        when 'f': rev_str[i]= 'k'
        when 'g': rev_str[i]= 'j'
        when 'h': rev_str[i]= 'i'
        when 'i': rev_str[i]= 'h'
        when 'j': rev_str[i]= 'g'
        when 'k': rev_str[i]= 'f'
        when 'l': rev_str[i]= 'e'
        when 'm': rev_str[i]= 'd'
        when 'n': rev_str[i]= 'c'
        when 'o': rev_str[i]= 'b'
        when 'p': rev_str[i]= 'a'
        when 'q','Q': rev_str[i]= '9'
        when 'r','R': rev_str[i]= '8'
        when 's','S': rev_str[i]= '7'
        when 't','T': rev_str[i]= '6'
        when 'u','U': rev_str[i]= '5'
        when 'v','V': rev_str[i]= '4'
        when 'w','W': rev_str[i]= '3'
        when 'x','X': rev_str[i]= '2'
        when 'y','Y': rev_str[i]= '1'
        when 'z','Z': rev_str[i]= '0'
        when 'A': rev_str[i]= 'P'
        when 'B': rev_str[i]= 'O'
        when 'C': rev_str[i]= 'N'
        when 'D': rev_str[i]= 'M'
        when 'E': rev_str[i]= 'L'
        when 'F': rev_str[i]= 'K'
        when 'G': rev_str[i]= 'J'
        when 'H': rev_str[i]= 'I'
        when 'I': rev_str[i]= 'H'
        when 'J': rev_str[i]= 'G'
        when 'K': rev_str[i]= 'F'
        when 'L': rev_str[i]= 'E'
        when 'M': rev_str[i]= 'D'
        when 'N': rev_str[i]= 'C'
        when 'O': rev_str[i]= 'B'
        when 'P': rev_str[i]= 'A'
      end
    end
    rev_str
  end
  
  def translate_lib
   {"Archive of Recorded Sound" => "Archive of Recorded Sound",
    "Art & Architecture" => "Art",
    "Branner (Earth Sciences & Maps)" => "Earth Sciences",
    "Classics" => "Classics",
    "Cubberley (Education)" => "Education",
    "Crown (Law)" => "Law",
    "East Asia" => "East Asia",
    "Engineering" => "Engineering",
    "Falconer (Biology)" => "Biology",
    "Green (Humanities & Social Sciences)" => "Green Library",
    "Hoover Library" => "Hoover Library",
    "Hoover Archives" => "Hoover Archives",
    "Jackson (Business)" => "Business",
    "Jonsson (Government Documents)" => "GovDocs",
    "Lane (Medical)" => "Medicine",
    "Miller (Hopkins Marine Station)" => "Hopkins Marine",
    "Math & Computer Science" => "Math & CompSci",
    "Meyer" => "",
    "Music" => "Music",
    "SAL3 (Off-campus)" => "",
    "SAL Newark (Off-campus)" => "",
    "Physics" => "Physics",
    "Stanford Auxiliary Library (On-campus)" => "",
    "Special Collections & Archives" => "Special Collections",
    "Stanford University Libraries" => "",
    "Swain (Chemistry & Chem. Engineering)" => "Chemistry",
    "Tanner (Philosophy Dept.)" => "Philosophy",
    "Applied Physics Department" => ""} 
  end
  
  def relator_terms
   {"acp" => "Art copyist",
    "act" => "Actor",
    "adp" => "Adapter",
    "aft" => "Author of afterword, colophon, etc.",
    "anl" => "Analyst",
    "anm" => "Animator",
    "ann" => "Annotator",
    "ant" => "Bibliographic antecedent",
    "app" => "Applicant",
    "aqt" => "Author in quotations or text abstracts",
    "arc" => "Architect",
    "ard" => "Artistic director ",
    "arr" => "Arranger",
    "art" => "Artist",
    "asg" => "Assignee",
    "asn" => "Associated name",
    "att" => "Attributed name",
    "auc" => "Auctioneer",
    "aud" => "Author of dialog",
    "aui" => "Author of introduction",
    "aus" => "Author of screenplay",
    "aut" => "Author",
    "bdd" => "Binding designer",
    "bjd" => "Bookjacket designer",
    "bkd" => "Book designer",
    "bkp" => "Book producer",
    "bnd" => "Binder",
    "bpd" => "Bookplate designer",
    "bsl" => "Bookseller",
    "ccp" => "Conceptor",
    "chr" => "Choreographer",
    "clb" => "Collaborator",
    "cli" => "Client",
    "cll" => "Calligrapher",
    "clt" => "Collotyper",
    "cmm" => "Commentator",
    "cmp" => "Composer",
    "cmt" => "Compositor",
    "cng" => "Cinematographer",
    "cnd" => "Conductor",
    "cns" => "Censor",
    "coe" => "Contestant -appellee",
    "col" => "Collector",
    "com" => "Compiler",
    "cos" => "Contestant",
    "cot" => "Contestant -appellant",
    "cov" => "Cover designer",
    "cpc" => "Copyright claimant",
    "cpe" => "Complainant-appellee",
    "cph" => "Copyright holder",
    "cpl" => "Complainant",
    "cpt" => "Complainant-appellant",
    "cre" => "Creator",
    "crp" => "Correspondent",
    "crr" => "Corrector",
    "csl" => "Consultant",
    "csp" => "Consultant to a project",
    "cst" => "Costume designer",
    "ctb" => "Contributor",
    "cte" => "Contestee-appellee",
    "ctg" => "Cartographer",
    "ctr" => "Contractor",
    "cts" => "Contestee",
    "ctt" => "Contestee-appellant",
    "cur" => "Curator",
    "cwt" => "Commentator for written text",
    "dfd" => "Defendant",
    "dfe" => "Defendant-appellee",
    "dft" => "Defendant-appellant",
    "dgg" => "Degree grantor",
    "dis" => "Dissertant",
    "dln" => "Delineator",
    "dnc" => "Dancer",
    "dnr" => "Donor",
    "dpc" => "Depicted",
    "dpt" => "Depositor",
    "drm" => "Draftsman",
    "drt" => "Director",
    "dsr" => "Designer",
    "dst" => "Distributor",
    "dtc" => "Data contributor ",
    "dte" => "Dedicatee",
    "dtm" => "Data manager ",
    "dto" => "Dedicator",
    "dub" => "Dubious author",
    "edt" => "Editor",
    "egr" => "Engraver",
    "elg" => "Electrician ",
    "elt" => "Electrotyper",
    "eng" => "Engineer",
    "etr" => "Etcher",
    "exp" => "Expert",
    "fac" => "Facsimilist",
    "fld" => "Field director ",
    "flm" => "Film editor",
    "fmo" => "Former owner",
    "fpy" => "First party",
    "fnd" => "Funder",
    "frg" => "Forger",
    "gis" => "Geographic information specialist ",
    "grt" => "Graphic technician",
    "hnr" => "Honoree",
    "hst" => "Host",
    "ill" => "Illustrator",
    "ilu" => "Illuminator",
    "ins" => "Inscriber",
    "inv" => "Inventor",
    "itr" => "Instrumentalist",
    "ive" => "Interviewee",
    "ivr" => "Interviewer",
    "lbr" => "Laboratory ",
    "lbt" => "Librettist",
    "ldr" => "Laboratory director ",
    "led" => "Lead",
    "lee" => "Libelee-appellee",
    "lel" => "Libelee",
    "len" => "Lender",
    "let" => "Libelee-appellant",
    "lgd" => "Lighting designer",
    "lie" => "Libelant-appellee",
    "lil" => "Libelant",
    "lit" => "Libelant-appellant",
    "lsa" => "Landscape architect",
    "lse" => "Licensee",
    "lso" => "Licensor",
    "ltg" => "Lithographer",
    "lyr" => "Lyricist",
    "mcp" => "Music copyist",
    "mfr" => "Manufacturer",
    "mdc" => "Metadata contact",
    "mod" => "Moderator",
    "mon" => "Monitor",
    "mrk" => "Markup editor",
    "msd" => "Musical director",
    "mte" => "Metal-engraver",
    "mus" => "Musician",
    "nrt" => "Narrator",
    "opn" => "Opponent",
    "org" => "Originator",
    "orm" => "Organizer of meeting",
    "oth" => "Other",
    "own" => "Owner",
    "pat" => "Patron",
    "pbd" => "Publishing director",
    "pbl" => "Publisher",
    "pdr" => "Project director",
    "pfr" => "Proofreader",
    "pht" => "Photographer",
    "plt" => "Platemaker",
    "pma" => "Permitting agency",
    "pmn" => "Production manager",
    "pop" => "Printer of plates",
    "ppm" => "Papermaker",
    "ppt" => "Puppeteer",
    "prc" => "Process contact",
    "prd" => "Production personnel",
    "prf" => "Performer",
    "prg" => "Programmer",
    "prm" => "Printmaker",
    "pro" => "Producer",
    "prt" => "Printer",
    "pta" => "Patent applicant",
    "pte" => "Plaintiff -appellee",
    "ptf" => "Plaintiff",
    "pth" => "Patent holder",
    "ptt" => "Plaintiff-appellant",
    "rbr" => "Rubricator",
    "rce" => "Recording engineer",
    "rcp" => "Recipient",
    "red" => "Redactor",
    "ren" => "Renderer",
    "res" => "Researcher",
    "rev" => "Reviewer",
    "rps" => "Repository",
    "rpt" => "Reporter",
    "rpy" => "Responsible party",
    "rse" => "Respondent-appellee",
    "rsg" => "Restager",
    "rsp" => "Respondent",
    "rst" => "Respondent-appellant",
    "rth" => "Research team head",
    "rtm" => "Research team member",
    "sad" => "Scientific advisor",
    "sce" => "Scenarist",
    "scl" => "Sculptor",
    "scr" => "Scribe",
    "sds" => "Sound designer",
    "sec" => "Secretary",
    "sgn" => "Signer",
    "sht" => "Supporting host",
    "sng" => "Singer",
    "spk" => "Speaker",
    "spn" => "Sponsor",
    "spy" => "Second party",
    "srv" => "Surveyor",
    "std" => "Set designer",
    "stl" => "Storyteller",
    "stm" => "Stage manager",
    "stn" => "Standards body",
    "str" => "Stereotyper",
    "tcd" => "Technical director",
    "tch" => "Teacher",
    "ths" => "Thesis advisor",
    "trc" => "Transcriber",
    "trl" => "Translator",
    "tyd" => "Type designer",
    "tyg" => "Typographer",
    "vdg" => "Videographer",
    "voc" => "Vocalist",
    "wam" => "Writer of accompanying material",
    "wdc" => "Woodcutter",
    "wde" => "Wood -engraver",
    "wit" => "Witness"}
  end

  def name_change_780_translations
   {"0" => "Continues",
    "1" => "Continues in part",
    "2" => "Supersedes",
    "3" => "Supersedes in part",
    "4" => "Merged from",
    "5" => "Absorbed",
    "6" => "Absorbed in part",
    "7" => "Separated from"} 
  end
  
  def name_change_785_translations
   {"0" => "Continued by",
    "1" => "Continued in part by",
    "2" => "Superseded by",
    "3" => "Superseded in part by",
    "4" => "Absorbed by",
    "5" => "Absorbed in part by",
    "6" => "Split into",
    "7" => "Merged with ... to form ...",
    "8" => "Changed back to"} 
  end
end