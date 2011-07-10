@file_assets
@destroyable_children
Feature: List deletable files for a document
  In order to know what file assets will get deleted
  As an editor
  I want to see a list of the current files which are only children of the current document and will get deleted with it
  
  @wip
  Scenario: Editor views the file list
    Given I am logged in as "archivist1" 
    And I am on the deletable file list page for hydrangea:fixture_mods_article1
    Then I should see a "li" element containing "hydrangea:fixture_uploaded_svg1 (OM_MANI_PADME_HUM-bw.svg)"
    
