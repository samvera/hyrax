require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HydraFedoraMetadataHelper do
  
  before(:all) do
    # @mock_ng_ds = mock("nokogiri datastream")
    # @mock_ng_ds.stubs(:kind_of?).with(ActiveFedora::NokogiriDatastream).returns(true)
    # @mock_ng_ds.stubs(:class).returns(ActiveFedora::NokogiriDatastream)
    # @mock_md_ds = stub(:stream_values=>"value")
    # datastreams = {"ng_ds"=>@mock_ng_ds,"simple_ds"=>@mock_md_ds}
    @resource = mock("fedora object")
    # @resource.stubs(:datastreams).returns(datastreams)
    # @resource.stubs(:datastreams_in_memory).returns(datastreams)
        
    @resource.stubs(:get_values_from_datastream).with("simple_ds", "subject", "").returns( ["topic1","topic2"] )

    @resource.stubs(:get_values_from_datastream).with("ng_ds", [:title, :main_title], "").returns( ["My Title"] )
    @resource.stubs(:get_values_from_datastream).with("ng_ds", [{:person=>1}, :given_name], "").returns( ["Bob"] )

    @resource.stubs(:get_values_from_datastream).with("empty_ds", "something", "").returns( [""] )
  end
  
  describe "fedora_text_field" do
    it "should generate a text field input with values from the given datastream" do
      generated_html = helper.fedora_text_field(@resource,"ng_ds",[:title, :main_title])
      # For Rails3:
      # generated_html.should have_selector "input.fieldselector" do |tag|
      #   tag.should have_selector "[value=?]", "title"
      #   tag.should have_selector "[value=?]", "main_title"
      # end
      # generated_html.should have_selector "input#title_main_title_0.editable-edit.edit" do |tag|
      #   tag.should have_selector "[value=?]", "My Title"
      #   tag.should have_selector "[name=?]","asset[ng_ds][title_main_title][0]"
      #   tag.should have_selector "[data-datastream-name=?]", "ng_ds" 
      generated_html.should have_selector "input.fieldselector" do |input|
        with_tag "[value=?]", "title"
        with_tag "[value=?]", "main_title"
      end
      generated_html.should have_selector "input#title_main_title_0.editable-edit.edit" do
        input.should have_selector "[value=?]", "My Title"
        input.should have_selector "[name=?]","asset[ng_ds][title_main_title][0]"
        input.should have_selector "[data-datastream-name=?]", "ng_ds" 
      end
    end
    it "should generate an ordered list of text field inputs" do
      generated_html = helper.fedora_text_field(@resource,"simple_ds","subject")
  # For Rails3
    #   generated_html.should have_selector "input#subject_0.editable-edit.edit" do |tag|
    #     tag.should have_selector "[value=?]", "topic1"
    #     tag.should have_selector "[name=?]", "asset[simple_ds][subject][0]"
    #   end
    #   generated_html.should have_selector "input#subject_1.editable-edit.edit" do |tag|
    #     tag.should have_selector "[value=?]", "topic2"
    #     tag.should have_selector "[name=?]", "asset[simple_ds][subject][1]"
    #   end
    #   generated_html.should have_selector "a.destructive.field"
    #   generated_html.should have_selector "input", :class=>"editable-edit", :id=>"subject_1", :name=>"asset[simple_ds][subject_1]", :value=>"topic9"                                                                                        
    #   generated_html.should be_html_safe
    # end
    # it "should render an empty control if the field has no values" do
    #   helper.fedora_text_field(@resource,"empty_ds","something").should have_selector "#something_0.editable-edit.edit", :value=>''
    # end
    # it "should limit to single-value output with no ordered list if :multiple=>false" do
    #   generated_html = helper.fedora_text_field(@resource,"simple_ds","subject", :multiple=>false)
    #   generated_html.should have_selector "input#subject.editable-edit.edit[value=topic1]" do |tag|
    #     tag.should have_selector "[name=?]", "asset[simple_ds][subject][0]"
    #   end
      generated_html.should have_selector "input#subject_0.editable-edit.edit" do |input|
        input.should have_selector "[value=?]", "topic1"
        input.should have_selector "[name=?]", "asset[simple_ds][subject][0]"
      end      
      generated_html.should have_selector "input#subject_1.editable-edit.edit" do |input|
        input.should have_selector "[value=?]", "topic2"
        input.should have_selector "[name=?]", "asset[simple_ds][subject][1]"
      end
      generated_html.should have_selector "a.destructive.field"
      generated_html.should have_selector "input", :class=>"editable-edit", :id=>"subject_1", :name=>"asset[simple_ds][subject_1]", :value=>"topic9"                                                                                        
    end
    it "should render an empty control if the field has no values" do
      helper.fedora_text_field(@resource,"empty_ds","something").should have_selector "#something_0.editable-edit.edit", :value => ""
    end
    it "should limit to single-value output with no ordered list if :multiple=>false" do
      generated_html = helper.fedora_text_field(@resource,"simple_ds","subject", :multiple=>false)      
      generated_html.should have_selector "input#subject.editable-edit.edit[value=topic1]" do |input|
        input.should have_selector "[name=?]", "asset[simple_ds][subject][0]"
      end                                                                                                                                                                                                
    end
  end
  
  describe "fedora_text_area" do
    it "should generate an ordered list of textile-enabled text area with values from the given datastream" do
      generated_html = helper.fedora_text_area(@resource,"simple_ds","subject")
    # Rails3:
    #   generated_html.should have_selector "textarea#subject_0.editable-edit.edit", :value=>"topic1"
    #   generated_html.should have_selector "textarea#subject_1.editable-edit.edit", :value=>"topic2"
    #   generated_html.should have_selector "a.destructive.field"
    # end
    # it "should render an empty control if the field has no values" do      
    #   helper.fedora_text_area(@resource,"empty_ds","something").should have_selector "li#something_0-container.field" do |tag|
    #     tag.should have_selector "span#something_0-text.editable-text.text[style=display:none;]", ""
    #     tag.should have_selector "textarea#something_0.editable-edit.edit", ""
    #   end
    # end
    # it "should limit to single-value output if :multiple=>false" do
    #   generated_html = helper.fedora_text_area(@resource,"simple_ds","subject", :multiple=>false)
    #   generated_html.should_not have_selector "ol"
    #   generated_html.should_not have_selector "li"
    #   generated_html.should have_selector "span#subject-container.field" do |tag|
    #     tag.should have_selector "span#subject-text.editable-text.text[style=display:none;]", "topic1"
    #     tag.should have_selector "textarea#subject.editable-edit.edit", "topic1"
    #   end
    #   generated_html.should be_html_safe
      generated_html.should have_selector "textarea#subject_0.editable-edit.edit", :value => "topic1"
      generated_html.should have_selector "textarea#subject_1.editable-edit.edit", :value => "topic2"
      generated_html.should have_selector "a.destructive.field"
    end
    it "should render an empty control if the field has no values" do      
      helper.fedora_text_area(@resource,"empty_ds","something").should have_selector "textarea#something_0.editable-edit.edit", :value => ""
    end
    it "should limit to single-value output if :multiple=>false" do
      generated_html = helper.fedora_text_area(@resource,"simple_ds","subject", :multiple=>false)
      generated_html.should have_selector "textarea#subject.editable-edit.edit", :value => "topic1"
    end
  end
  
  describe "fedora_select" do
    it "should generate a select with values from the given datastream" do
      generated_html = helper.fedora_select(@resource,"simple_ds","subject", :choices=>["topic1","topic2", "topic3"])
      # Rails3:
      # generated_html.should have_selector "select.metadata-dd[name='asset[simple_ds][subject][0]']" do |tag|
      #   tag.should have_selector "[rel=?]", "subject" 
      #   tag.should have_selector "option[value=topic1][selected=selected]"
      #   tag.should have_selector "option[value=topic2][selected=selected]"
      #   tag.should have_selector "option[value=topic3]"
      generated_html.should have_selector "select.metadata-dd[name='asset[simple_ds][subject][0]']" do |tag|
        tag.should have_selector "option[value=topic1][selected=selected]"
        tag.should have_selector "option[value=topic2][selected=selected]"
        tag.should have_selector "option[value=topic3]"
      end
    end
    it "should return the product of fedora_text_field if :choices is not set" do
      helper.expects(:fedora_text_field).returns("fake response")
      generated_html = helper.fedora_select(@resource,"simple_ds","subject")
      generated_html.should == "fake response"
    end
  end

  describe "fedora_date_select" do
    it "should generate a date picker with values from the given datastream" do
      generated_html = helper.fedora_date_select(@resource,"simple_ds","subject")
      # Rails3
      # generated_html.should have_selector ".date-select[name='asset[simple_ds][subject]']" do |tag|
      #   tag.should have_selector "[rel=?]", "subject" 
      #   tag.should have_selector "input#subject-sel-y.controlled-date-part.w4em"
      #   tag.should have_selector "select#subject-sel-mm.controlled-date-part" do |tag|
      #     tag.should have_selector "option[value=01]", "January"
      #     tag.should have_selector "option[value=12]", "December"
      generated_html.should have_selector ".date-select[name='asset[simple_ds][subject]']" do |tag|
        tag.should have_selector "input#subject-sel-y.controlled-date-part.w4em"
        tag.should have_selector "select#subject-sel-mm.controlled-date-part" do |tag|
          tag.should have_selector "option[value=01]", "January"
          tag.should have_selector "option[value=12]", "December"
        end
        tag.should have_selector "select#subject-sel-dd.controlled-date-part" do |tag|
          tag.should have_selector "option[value=01]", "01"
          tag.should have_selector "option[value=31]", "31"
        end

      end
    end
  end
  
  describe "fedora_checkbox" do
    it "should generate a set of checkboxes with values from the given datastream" 
  end
  
  describe "all field generators" do
    it "should include any necessary field_selector info" do
      field_selectors_regexp = helper.field_selectors_for("ng_ds",[:title, :main_title]).gsub('/','\/').gsub(']','\]').gsub('[','\[')
      ["fedora_text_field", "fedora_text_area", "fedora_select", "fedora_date_select"].each do |method|
        generated_html = eval("helper.#{method}(@resource,\"ng_ds\",[:title, :main_title])")
        generated_html.should match( field_selectors_regexp )
      end
      generated_html = helper.fedora_select(@resource,"ng_ds",[:title, :main_title], :choices=>["choice1"])
      generated_html.should match( field_selectors_regexp )
    end
  end
  
  describe "fedora_text_field_insert_link" do
    it "should generate a link for inserting a fedora_text_field into the page" do
      helper.fedora_text_field_insert_link("ng_ds",[:title, :main_title]).should have_selector "a.addval.textfield[href='#']"
    end
  end
  
  describe "fedora_text_area_insert_link" do
    it "should generate a link for inserting a fedora_text_area into the page" do
      helper.fedora_text_area_insert_link("ng_ds",[:title, :main_title]).should have_selector "a.addval.textarea[href='#']"
    end
      
  end
  
  describe "fedora_field_label" do
    it "should generate a label with appropriate @for attribute" do
      helper.fedora_field_label("ng_ds",[:title, :main_title], "Title:").should have_selector "label[for=title_main_title]", :content => "Title:"
    end 
    it "should display the field name if no label is provided" do
      helper.fedora_field_label("ng_ds",[:title, :main_title]).should have_selector "label[for=title_main_title]", :content=>"title_main_title"
    end
  end
  
  describe "field_selectors_for" do
    it "should generate any necessary field_selector values for the given field" do
      generated_html = helper.field_selectors_for("myDsName", [{:name => 3}, :name_part])
      # Rails3
      # generated_html.should have_selector "input.fieldselector[type=hidden][name='field_selectors[myDsName][name_3_name_part][][name]']" do |tag|
      #   tag.should have_selector "[rel=name_3_name_part]"
      #   tag.should have_selector "[value=3]"
      # end
      # generated_html.should have_selector "input.fieldselector[type=hidden][name='field_selectors[myDsName][name_3_name_part][]']" do |tag|
      #   tag.should have_selector "[rel=name_3_name_part]"
      #   tag.should have_selector "[value=name_part]"
      generated_html.should have_selector "input.fieldselector[type=hidden][name='field_selectors[myDsName][name_3_name_part][][name]']" do |input|
        input.should have_selector "[value=3]"
      end
      generated_html.should have_selector "input.fieldselector[type=hidden][name='field_selectors[myDsName][name_3_name_part][]']" do |input|
        input.should have_selector "[value=name_part]"
      end
      # ordering is important.  this next line makes sure that the inputs are in the correct order
      # (tried using CSS3 nth-of-type selectors in have_selector but it didn't work)
      generated_html.should match(/<input.*name="field_selectors\[myDsName\]\[name_3_name_part\]\[\]\[name\]".*\/><input.*name="field_selectors\[myDsName\]\[name_3_name_part\]\[\].*value="name_part" .*\/>/)
    end
    it "should not generate any field selectors if the field key is not an array" do
      helper.field_selectors_for("myDsName", :description).should == ""
    end
  end
  
  describe "hydra_form_for" do
    it "should generate an entire form" do
      pending
      eval_erb(%(
        <% hydra_form_for @resource do |h| %>
          <h2>Hello</h2>
          <%= h.fedora_text_field %>
        <% end %>
      )).should match_html("<h2>Hello</h2> blah blah blah ")
    end
  end
end
