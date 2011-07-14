Feature: GenericImage Create View
  I want to see appropriate information for creating GenericImage objects

  Scenario: html5 valid
    Given I am logged in as "archivist1"
    When I create a new generic_image
    Then the page should be HTML5 valid
