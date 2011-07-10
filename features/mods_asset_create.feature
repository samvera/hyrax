@new @dataset 
Feature: Add a new Dataset
  In order to publish a Dataset
  As a Depositor
  I want to submit a new MODS Asset
  
  Scenario: Visit New MODS Asset Page
    Given I am logged in as "archivist1"
    And I am on the home page	
    And I create a new mods_asset
    Then I should see "Describe the Asset"
    And the "title_info_main_title" field should contain ""
