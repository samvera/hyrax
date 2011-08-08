@new @dataset 
Feature: ModsAsset Create View
  As a Depositor
  I want to see appropriate information for creating ModsAsset objects
  In order to submit a new MODS Asset
  

  Scenario: Create Page for New ModsAsset Object
    Given I am logged in as "archivist1@example.com"
    When I create a new mods_asset
    Then I should see "Created a Mods Asset"
    And I should see "Now it's ready to be edited."
    And I should see "Describe the Asset"
    And the "person_0_first_name" field should contain ""
    And the "title_info_main_title" field should contain ""

  Scenario: html5 valid
    Given I am logged in as "archivist1@example.com"
    When I create a new mods_asset
    Then the page should be HTML5 valid

