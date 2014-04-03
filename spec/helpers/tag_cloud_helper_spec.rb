require "spec_helper"

describe TagCloudHelper do
  describe "tag_cloud_for" do
    before do
      @config = Blacklight::Configuration.new do |config|
        config.add_facet_field 'basic_field'
      end
      helper.stub(:blacklight_config => @config)
      @response = double()
      @mock_items = []
      [322, 322, 32, 11, 6 , 6].each { |n| @mock_items << double(:hits => n, :name =>n.to_s)}
      @mock_facet = double(name:'basic_field', items:@mock_items, sort:nil, offset:nil)
      helper.should_receive(:facet_by_field_name).with("basic_field").and_return(@mock_facet)
    end
  
    it "should set basic local variables" do
      helper.should_receive(:render).with(hash_including(:partial => 'catalog/tag_cloud', 
                                                         :locals => { 
                                                            :solr_field => 'basic_field',
                                                            :facet_field => helper.blacklight_config.facet_fields['basic_field'],
                                                            :display_facet => @mock_facet,  
                                                            :scale_factor => 1/(322/15.0),
                                                            :limit => @mock_items.length
                                                            }
                                                        ))
      helper.tag_cloud_for("basic_field")
    end
    it "should allow you to set granularity" do
      helper.should_receive(:render) do |arg|
        arg[:locals][:scale_factor].should == 1/(322/100.0)
      end
      helper.tag_cloud_for("basic_field", granularity:100)
    end
    it "should allow you to explicitly set tag scale_factor" do
      @mock_facet = double(:name => 'asdf', :items => [1,2,3])
      helper.should_receive(:render) do |arg|
        arg[:locals][:scale_factor].should == 0.025
      end
      helper.tag_cloud_for("basic_field", locals:{scale_factor: 0.025})
    end
    it "should limit number of items rendered if limit is provided" do                                                    
      helper.should_receive(:render_facet_value).exactly(2).times                                          
      helper.tag_cloud_for("basic_field", limit:2)
    end
  end
  
end