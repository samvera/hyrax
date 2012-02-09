@new @dataset 
Feature: ModsAsset Create View
  As a Depositor
  I want to see appropriate information for creating ModsAsset objects
  In order to submit a new MODS Asset
  
  Scenario: Create Workflow for New ModsAsset Object
    Given I am logged in as "archivist1@example.com"
    When I create a new mods_asset
    Then show me the page
    Then I should see "Created a Mods Asset"
    And I should see "Now it's ready to be edited."
    And the "person_0_first_name" field should contain ""
    
  Scenario: html5 valid
    Given I am logged in as "archivist1@example.com"
    When I create a new mods_asset
    Then the page should be HTML5 valid
