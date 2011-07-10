@show @articles
Feature: Show a document
  In order to [goal]
  [stakeholder]
  wants [behaviour]
  
  @overwritten
  Scenario: Public visit Publicly Viewable Document
    Given I am on the show document page for hydrangea:fixture_mods_article1
    Then I should see "ARTICLE TITLE"
    And I should see "GIVEN NAMES"
    And I should see "FAMILY NAME"
    And I should see "FACULTY, UNIVERSITY"
    And I should see "TOPIC 1"
    And I should see "TOPIC 2"
    And I should see "CONTROLLED TERM"
    And I should not see a link to "the edit document page for hydrangea:fixture_mods_article1"
   
  @local
  Scenario: Public visit Publicly Viewable Document
    Given I am on the show document page for libra-oa:1
    Then I should see "The Smallest Victims of the"
    And I should see "Mary"
    And I should see "Gibson"
    And I should see "University of Virginia"
    And I should see "white plague"
    And I should see "pediatric nursing"
    And I should see "UVA Libra Contributor's License"
    And I should not see a link to "the edit document page for libra-oa:1"
  
  Scenario: Public visit Document Show Page for a private document  
    Given I am on the show document page for hydrangea:fixture_archivist_only_mods_article
    Then I should be on the search page
    And I should see "You do not have sufficient access privileges to read this document, which has been marked private" within ".notice"
  
  @overwritten
  Scenario: Superuser visits Document Show Page for a private document
    Given I am a superuser
    And I am on the show document page for hydrangea:fixture_archivist_only_mods_article
    Then I should see "Article for Archivist Eyes Only"
   
  @local
  Scenario: Superuser visits Document Show Page for a private document
    Given I am a superuser
    And I am on the show document page for libra-oa:7
    Then I should see "Khadzhi-Murat's Silence"
  
  @overwritten
  Scenario: Archivist visits Show Page for Restricted Document
    Given I am logged in as "archivist1" 
    And I am on the show document page for hydrangea:fixture_archivist_only_mods_article
    Then I should see "Article for Archivist Eyes Only"
    And I should see "Sally"
    And I should see "Whocontributes"
    And I should see "University of Contributions"
    And I should see "contributing"
    And I should see "exclusiveness"
    And I should not see a link to "the edit document page for hydrangea:fixture_public_mods_article"
  
  @local
  Scenario: Archivist visits Show Page for Restricted Document
    Given I am logged in as "archivist1" 
    And I am on the show document page for libra-oa:7
    Then I should see "Khadzhi-Murat's Silence"
    And I should see "David Herman"
    And I should see "University of Virginia"

