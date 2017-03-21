export default class VisibilityComponent {
  /**
   * Initialize the save controls
   * @param {jQuery} element the jquery selector for the visibility component
   * @param {AdminSetWidget} adminSetWidget the control for the adminSet dropdown
   */
  constructor(element, adminSetWidget) {
    this.element = element
    this.adminSetWidget = adminSetWidget
    this.form = element.closest('form')
    $('.collapse').collapse({ toggle: false })
    element.find("[type='radio']").on('change', () => { this.showForm() })
    this.showForm()
    this.limitByAdminSet()
  }

  showForm() {
    this.openSelected()
  }

  // Collapse all Visibility sub-options
  collapseAll() {
    $('.collapse').collapse('hide');
  }

  // Open the selected Visibility's sub-options, collapsing all others
  openSelected() {
    let selected = this.element.find("[type='radio']:checked")

    let target = selected.data('target')

    if(target) {
      // Show the target suboption and hide all others
      $('.collapse' + target).collapse('show');
      $('.collapse:not(' + target + ')').collapse('hide');
    }
    else {
      this.collapseAll()
    }
  }

  // Limit visibility options based on selected AdminSet (if enabled)
  limitByAdminSet() {
    if(this.adminSetWidget) {
      this.adminSetWidget.on('change', (data) => this.restrictToVisibility(data))
      if (this.adminSetWidget.isEmpty()) {
          console.error("No data was passed from the admin set. Perhaps there are no selectable options?")
          return
      }
      this.restrictToVisibility(this.adminSetWidget.data())
    }
  }

  // Restrict visibility and/or release date to match the AdminSet requirements (if any)
  restrictToVisibility(data) {
    // visibility requirement is in HTML5 'data-visibility' attr
    let visibility = data['visibility']
    // release date requirement is in HTML5 'data-release-date' attr
    let release_date = data['releaseDate']
    // if release_date is flexible (i.e. before date), then 'data-release-before-date' attr will be true
    let release_before = data['releaseBeforeDate']

    // Restrictions require either a visibility requirement or a release_date requirement (or both)
    if(visibility || release_date) {
      this.applyRestrictions(visibility, release_date, release_before)
    }
    else {
      this.enableAllOptions()
    }
  }

  // Apply visibility/release restrictions based on selected AdminSet
  applyRestrictions(visibility, release_date, release_before)
  {
     // If immediate release required and visibility specified
     if(this.isToday(release_date) && visibility) {
       // Select required visibility
       this.selectVisibility(visibility)
     }
     else if(this.isToday(release_date)) {
       // No visibility required, but must be released today. Disable embargo & lease.
       this.disableEmbargoAndLease();
     }
     // Otherwise if future date and release_before==true, must be released between today and release_date
     else if(release_date && release_before) {
       this.enableReleaseNowOrEmbargo(visibility, release_date, release_before)
     }
     // Otherwise if future date and release_before==false, this is a required embargo (must be released on specific future date)
     else if(release_date) {
       this.requireEmbargo(visibility, release_date)
     }
     // If nothing above matched, then there's no release date required. So, release now or embargo is fine
     else {
       this.enableReleaseNowOrEmbargo(visibility, release_date, release_before)
     }
  }

  // Select given visibility option. All others disabled.
  selectVisibility(visibility) {
    this.element.find("[type='radio'][value='" + visibility + "']").prop("checked", true).prop("disabled", false)
    this.element.find("[type='radio'][value!='" + visibility + "']").prop("disabled", true)
    // Ensure required option is opened in form
    this.showForm()
  }

  // Allow for immediate release or embargo, based on visibility settings (if any)
  enableReleaseNowOrEmbargo(visibility, release_date, release_before) {
    if(visibility) {
      // Enable ONLY the allowable visibility options (specified visibility or embargo)
      this.enableVisibilityOptions([visibility, "embargo"])
    }
    else {
      // Allow all visibility options EXCEPT lease
      this.disableVisibilityOptions(["lease"])
    }

    // Limit valid embargo release dates
    this.restrictEmbargoDate(release_date, release_before)

    // Select Visibility after embargo (if any)
    this.selectVisibilityAfterEmbargo(visibility)
  }

  // Require a specific embargo date (and possibly also specific visibility)
  requireEmbargo(visibility, release_date) {
    // This a required embargo date
    this.selectVisibility("embargo")

    // Limit valid embargo release dates
    this.restrictEmbargoDate(release_date, false)

    // Select Visibility after embargo (if any)
    this.selectVisibilityAfterEmbargo(visibility)
  }

  // Disable Embargo and Lease options. Work must be released immediately
  disableEmbargoAndLease() {
    this.disableVisibilityOptions(["embargo","lease"])
  }

  // Enable one or more visibility option (based on array of passed in options),
  // disabling all other options
  enableVisibilityOptions(options) {
    let matchEnabled = this.getMatcherForVisibilities(options)
    let matchDisabled = this.getMatcherForNotVisibilities(options)

    // Enable all that match "matchEnabled" (if any), and disable those matching "matchDisabled"
    if(matchEnabled) {
      this.element.find(matchEnabled).prop("disabled", false)
    }
    this.element.find(matchDisabled).prop("disabled", true)
  }

  // Disable one or more visibility option (based on array of passed in options),
  // disabling all other options
  disableVisibilityOptions(options) {
    let matchDisabled = this.getMatcherForVisibilities(options)
    let matchEnabled = this.getMatcherForNotVisibilities(options)

    // Disable those matching "matchDisabled" (if any), and enable all that match "matchEnabled"
    if(matchDisabled) {
      this.element.find(matchDisabled).prop("disabled", true)
    }
    this.element.find(matchEnabled).prop("disabled", false)
  }

  // Create a jQuery matcher which will match for all the specified options
  // (expects an array of options).
  // This creates a logical OR matcher, whose format looks like:
  // "[type='radio'][value='one'],[type='radio'][value='two']"
  getMatcherForVisibilities(options) {
    let initialMatcher = "[type='radio']"
    let matcher = ""
    // Loop through specified visibility options, creating a logical OR matcher
    for(let i = 0; i < options.length; i++) {
      if(i > 0) {
        matcher += ","
      }
      matcher += initialMatcher + "[value='" + options[i] + "']"
    }
    return matcher
  }

  // Create a jQuery matcher which will match all options EXCEPT the specified options
  // (expects an array of options).
  // This creates a logical AND NOT matcher, whose format looks like:
  // "[type='radio'][value!='one'][value!='two']"
  getMatcherForNotVisibilities(options) {
    let initialMatcher = "[type='radio']"
    let matcher = initialMatcher
    // Loop through specified visibility options, creating a logical AND NOT matcher
    for(let i = 0; i < options.length; i++) {
      matcher += "[value!='" + options[i] + "']"
    }
    return matcher
  }

  // Based on release_date/release_before, limit valid options for embargo date
  // * release_date is a date of format YYYY-MM-DD
  // * release_before is true if dates before release_date are allowabled, false otherwise.
  restrictEmbargoDate(release_date, release_before) {
    let embargoDateInput = this.getEmbargoDateInput()
    // Dates before today are not valid
    embargoDateInput.prop("min", this.getToday());

    if(release_date) {
      // Dates AFTER release_date are not valid
      embargoDateInput.prop("max", release_date);
    }
    else {
      embargoDateInput.prop("max", "");
    }

    // If release before dates are NOT allowed, set exact embargo date and disable field
    if(release_date && !release_before) {
      embargoDateInput.val(release_date)
      embargoDateInput.prop("disabled", true)
    }
    else {
      embargoDateInput.prop("disabled", false)
    }
  }

  // Based on embargo visibility, select required visibility (if any)
  selectVisibilityAfterEmbargo(visibility) {
    let visibilityInput = this.getVisibilityAfterEmbargoInput()
    // If a visibility is required, select it and disable field
    if(visibility) {
      visibilityInput.find("option[value='" + visibility + "']").prop("selected", true)
      visibilityInput.prop("disabled", true)
    }
    else {
      visibilityInput.prop("disabled", false)
    }
  }

  // Ensure all visibility options are enabled
  enableAllOptions() {
    this.element.find("[type='radio']").prop("disabled", false)
    this.getEmbargoDateInput().prop("disabled", false)
    this.getVisibilityAfterEmbargoInput().prop("disabled", false)
  }

  // Get input field corresponding to embargo date
  getEmbargoDateInput() {
    return this.element.find("[type='date'][id$='_embargo_release_date']")
  }

  // Get input field corresponding to visibility after embargo expires
  getVisibilityAfterEmbargoInput() {
    return this.element.find("select[id$='_visibility_after_embargo']")
  }

  // Get today's date in YYYY-MM-DD format
  getToday() {
    let today = new Date()
    let dd = today.getDate()
    let mm = today.getMonth() + 1  // January is month 0
    let yyyy = today.getFullYear()

    // prepend zeros as needed
    if(dd < 10) {
      dd = '0' + dd
    }
    if(mm < 10) {
      mm = '0' + mm
    }
    return yyyy + '-' + mm + '-' + dd
  }

  // Return true if datestring represents today's date
  isToday(dateString) {
    let today = new Date(this.getToday())
    let date =  new Date(dateString)
    return date.getTime() === today.getTime()
  }
}
