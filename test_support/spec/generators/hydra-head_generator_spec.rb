# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "generators/hydra-head/hydra-head_generator"

describe HydraHeadGenerator do

  describe "methods from BlacklightGenerator" do
    it "should re-use Blacklight's generator methods where convenient" do
      # BlacklightGenerator.expects(:next_migration_number)
      # HydraHeadGenerator.next_migration_number("foopath")
      
      BlacklightGenerator.expects(:better_migration_template)
      HydraHeadGenerator.better_migration_template("foopath")
    end
  end

end

