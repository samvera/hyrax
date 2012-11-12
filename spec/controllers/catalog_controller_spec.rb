# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe CatalogController do
  before do
    GenericFile.any_instance.stubs(:terms_of_service).returns('1')
    GenericFile.any_instance.stubs(:characterize_if_changed).yields
    @user = FactoryGirl.find_or_create(:user)
    sign_in @user
    User.any_instance.stubs(:groups).returns([])
    controller.stubs(:clear_session_user) ## Don't clear out the authenticated session
  end
  after do
    @user.delete
  end
  describe "#index" do
    before (:all) do
      GenericFile.any_instance.stubs(:terms_of_service).returns('1')
      @gf1 =  GenericFile.new(title:'Test Document PDF', filename:'test.pdf', read_groups:['public'])
      @gf1.apply_depositor_metadata('mjg36')
      @gf1.save
      @gf2 =  GenericFile.new(title:'Test 2 Document', filename:'test2.doc', contributor:'Contrib1', read_groups:['public'])
      @gf2.apply_depositor_metadata('mjg36')
      @gf2.save
    end
    after (:all) do
      @gf1.delete
      @gf2.delete
    end
    describe "term search" do
      before do
         xhr :get, :index, :q =>"pdf"
      end
      it "should find pdf files" do
        response.should be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(1)
        assigns(:document_list)[0].fetch(:generic_file__title_t)[0].should eql('Test Document PDF')
      end
    end
    describe "facet search" do
      before do
        xhr :get, :index, :fq=>"{!raw f=generic_file__contributor_facet}Contrib1"
      end
      it "should find facet files" do
        response.should be_success
        response.should render_template('catalog/index')
        assigns(:document_list).count.should eql(2)
      end
    end
  end

  describe "#recent" do
    before do
      @gf1 = GenericFile.new(title:'Generic File 1', contributor:'contributor 1', resource_type:'type 1', read_groups:['public'])
      @gf1.apply_depositor_metadata('mjg36')
      @gf1.save
      sleep 1 # make sure next file is not at the same time compare
      @gf2 = GenericFile.new(title:'Generic File 2', contributor:'contributor 2', resource_type:'type 2', read_groups:['public'])
      @gf2.apply_depositor_metadata('mjg36')
      @gf2.save
      sleep 1 # make sure next file is not at the same time compare
      @gf3 = GenericFile.new(title:'Generic File 3', contributor:'contributor 3', resource_type:'type 3', read_groups:['public'])
      @gf3.apply_depositor_metadata('mjg36')
      @gf3.save
      sleep 1 # make sure next file is not at the same time compare
      @gf4 = GenericFile.new(title:'Generic File 4', contributor:'contributor 4', resource_type:'type 4', read_groups:['public'])
      @gf4.apply_depositor_metadata('mjg36')
      @gf4.save
      xhr :get, :recent
    end

    after do
      @gf1.delete
      @gf2.delete
      @gf3.delete
      @gf4.delete
    end

    it "should find my 4 files" do
      response.should be_success
      response.should render_template('catalog/recent')
      assigns(:recent_documents).count.should eql(4)
      # the order is reversed since the first in should be the last out in descending time order
      #assigns(:recent_documents).each {|doc| logger.info doc.fetch(:generic_file__title_t)[0]}
      lgf4 = assigns(:recent_documents)[0]
      lgf3 = assigns(:recent_documents)[1]
      lgf2 = assigns(:recent_documents)[2]
      lgf1 = assigns(:recent_documents)[3]
      lgf4.fetch(:generic_file__title_t)[0].should eql(@gf4.title[0])
      lgf4.fetch(:generic_file__contributor_t)[0].should eql(@gf4.contributor[0])
      lgf4.fetch(:generic_file__resource_type_t)[0].should eql(@gf4.resource_type[0])
      lgf1.fetch(:generic_file__title_t)[0].should eql(@gf1.title[0])
      lgf1.fetch(:generic_file__contributor_t)[0].should eql(@gf1.contributor[0])
      lgf1.fetch(:generic_file__resource_type_t)[0].should eql(@gf1.resource_type[0])
    end
  end
end
