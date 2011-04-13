module CatalogHelper
  
  include Blacklight::SolrHelper
  
  def format_date date
   date.strftime("%b. %e, %Y")
  end
    
  
  def depositor_string depositor=nil
    "#{depositor}" unless depositor.nil? 
  end
  def get_children pid
    par = solr_facet_params(:is_part_of_s)
    query="_query_:\"{!dismax qf=$qf_dismax pf=$pf_dismax}is_part_of_s:info\\:fedora/#{pid.gsub(":",'\:')}\"" 
    # start query of with user supplied query term
      #q << "_query_:\"{!dismax qf=$qf_dismax pf=$pf_dismax}#{user_query}\""
    (response, document_list) = get_search_results( :q=>query )
    par.inspect
  end

  def author_list(doc)
    get_persons_from_roles(doc,['author','collaborator','creator','contributor']).map {|person| format_person_string(person[:first],person[:last],person[:institution])}
  end

  def researcher_list(doc)
    get_persons_from_roles(doc,['research team head']).map {|person| format_person_string(person[:first],person[:last],person[:institution])}
  end

  def get_persons_from_roles(doc,roles,opts={})
    i = 0
    persons =[]
    while i < 10
      persons_roles = [] # reset the array
      persons_roles = doc["person_#{i}_role_t"].map{|w|w.strip.downcase} unless doc["person_#{i}_role_t"].nil?
      if persons_roles and (persons_roles & roles).length > 0
        persons << {:first => doc["person_#{i}_first_name_t"], :last=> doc["person_#{i}_last_name_t"], :institution => doc["person_#{i}_institution_t"]}
      end
      i += 1
    end
    return persons
  end

  def format_person_string first_name, last_name, affiliation, opt={}
    full_name = [first_name, last_name].join(" ").strip
    affiliation = affiliation.nil? ? "" : "(#{affiliation})"
    [full_name, affiliation].join(" ").concat(";")
  end

  def journal_info(doc)
    title = doc.get(:journal_title_info_main_title_t)
		pub_date = doc.get(:journal_issue_publication_date_t)
		volume = doc.get(:journal_issue_volume_t)
		issue = doc.get(:journal_issue_volume_t)
		start_page = doc.get(:journal_issue_pages_start_t) 
    end_page = doc.get(:journal_issue_end_page_t)
    journal_info = "#{title}. #{pub_date}; #{volume} ( #{issue} ): #{start_page} - #{end_page}"
    journal_info = "" if journal_info.match(/^\.\s+;\s+\(\s+\)\:\s+-\s*$/)
    journal_info
  end

  def short_abstract(doc,max=250)
		abstract = doc.get(:abstract_t)
    if abstract.blank?
      return ""
    elsif abstract.length < max
      return abstract
    else
      return abstract[0..max].strip.concat("...")
    end
  end

  def admin_info(doc)
    info =<<-EOS
      Deposited: #{format_date(DateTime.parse(doc.get(:system_create_dt)).to_time)} 
		  | By: #{depositor_string(doc.get(:depositor_t))} 
		  | Status: Created
    EOS
  end

end
