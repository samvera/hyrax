@edit @articles
Feature: Edit a ModsAsset object
  As a Depositor
  I want to see appropriate information for editing ModsAsset objects

  # I'm not sure what this scenario is supposed to be testing.  It seems to no longer be valid w/ the ModsAsset Submission Workflow.  
  # Scenario: Edit Page for Mods Asset
  #   Given I am logged in as "archivist1@example.com" 
  #   When I am on the edit publication page for hydrangea:fixture_mods_article1 
  #   Then I should see "ARTICLE TITLE" within "#title_fieldset"    
  #   And I should see a "Save Description" button

  Scenario: Visit Document Edit Page and see the file assets
    Given I am logged in as "archivist1@example.com" 
    When I am on the edit files page for libra-oa:1
    #This isn't in the page in the new edit flow.
    #Then I should see "The Smallest Victims of the " within "#title_fieldset"
		And I should see "gibson.pdf" within "tr.file_asset"
		And I should see "Delete" within "tr.file_asset"

  Scenario: Viewing browse/edit buttons
    Given I am logged in as "archivist1@example.com" 
    When I am on the edit document page for hydrangea:fixture_mods_article1
    Then I should see a "span" tag with a "class" attribute of "edit-browse"

  Scenario: html5 valid
    Given I am logged in as "archivist1@example.com"
    When I am on the edit document page for hydrangea:fixture_mods_article1 
    Then the page should be HTML5 valid

  # the mockups for Libra did not have a delete confirmation
  @overwritten
  Scenario: Delete Confirmation on Edit Page
    Given I am logged in as "archivist1@example.com" 
    When I am on the edit document page for hydrangea:fixture_mods_article1 
    Then I should see a "div" tag with an "id" attribute of "delete_dialog_container"
    And I should see "Permanently delete"
