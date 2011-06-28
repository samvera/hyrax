# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "generators/hydra/head_generator"
require "generators/blacklight/blacklight_generator"

describe Hydra::HeadGenerator do

  describe "methods from BlacklightGenerator" do
    it "should re-use Blacklight's generator methods where convenient" do
      pending "spec failure with no method error"
      # BlacklightGenerator.expects(:next_migration_number)
      # HydraHeadGenerator.next_migration_number("foopath")
      
      BlacklightGenerator.expects(:better_migration_template)
      Hydra::HeadGenerator.better_migration_template("foopath")
    end
  end

end

