# Marked @pending until we are able to load solr fixtures.  
# Currently failing with jetty index because there aren't enough technology facet values in the jetty index to trigger rendering of more/less feature
# This test will pass with the full SALT sample dataset (from SALT disk image)
@facets @pending
Feature: display more/less links
  As a user
  In order to hide facets when there are more than the configurable amount
  I want to see more and less li elements

  Scenario: Viewing the facets
    When I am on the home page
    Then I should see "more technologies"
    And I should see "less technologies"

  Scenario: Facets on the record view
    Given I am on the show document page for druid:sb733gr4073
    Then I should see "more technologies"
    And I should see "less technologies"
  
  
  
