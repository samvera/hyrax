@edit @articles
Feature: Edit a document
  In order to [goal]
  [stakeholder]
  wants [behaviour]
  
  Scenario: Visit Document Edit Page
    Given I am logged in as "archivist1" 
    And I am on the edit document page for hydrangea:fixture_mods_article1 
    Then I should see "ARTICLE TITLE" within "#title_fieldset"    
    And I should see a "Save Description" button

  Scenario: Visit Document Edit Page and see the file assets
     Given I am logged in as "archivist1" 
     And I am on the edit document page for libra-oa:1
     Then I should see "The Smallest Victims of the " within "#title_fieldset"
		 Then I should see "gibson.pdf" within "tr.file_asset"
		 And I should see "Delete this" within "a#delete_asset_link"

  Scenario: Viewing browse/edit buttons
    Given I am logged in as "archivist1" 
    And I am on the edit document page for hydrangea:fixture_mods_article1
    Then I should see a "span" tag with a "class" attribute of "edit-browse"


  # the mockups for Libra did not have a delete confirmation
  @overwritten
  Scenario: Delete Confirmation on Edit Page
    Given I am logged in as "archivist1" 
    And I am on the edit document page for hydrangea:fixture_mods_article1 
    Then I should see a "div" tag with an "id" attribute of "delete_dialog_container"
    And I should see "Permanently delete"

