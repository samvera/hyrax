export default class {
  constructor(element) {
    this.element = element
  }

  setup() {
    this.formatDateOnLoad();
    // Watch for changes to "release_period" radio inputs
    let releasePeriodInput = this.element.find("input[type='radio'][name$='[release_period]']")
    $(releasePeriodInput).on('change', () => { this.releasePeriodSelected() })
    this.releasePeriodSelected()

    // Watch for changes to "release_varies" radio inputs
    let releaseVariesInput = this.element.find("input[type='radio'][name$='[release_varies]']")
    $(releaseVariesInput).on('change', () => { this.releaseVariesSelected() })
    this.releaseVariesSelected()
    this.validateEmbargoDate();
  }

  // Based on the "release_period" radio selected, enable/disable other options
  releasePeriodSelected() {
    let selected = this.element.find("input[type='radio'][name$='[release_period]']:checked")
    
    switch(selected.val()) {
      // If "No Delay" (now) selected
      case "now":
        this.disableReleaseVariesOptions()
        this.disableReleaseFixedDate()
        this.enableVisibilityRestricted()
        break;

      // If "Varies" ("") selected
      case "":
        this.enableReleaseVariesRadio()
        this.disableReleaseFixedDate()
        this.disableVisibilityRestricted()
        // Also check if a release "Varies" sub-option previously selected
        this.releaseVariesSelected()
        break;

      // If "Fixed" selected
      case "fixed":
        this.disableReleaseVariesOptions()
        this.enableReleaseFixedDate()
        this.disableVisibilityRestricted()
        break;

      // Nothing selected
      default:
        this.disableReleaseVariesOptions()
        this.disableReleaseFixedDate()
        this.disableVisibilityRestricted()
    }
  }

  // Based on the "release_varies" radio selected, enable/disable other options
  releaseVariesSelected() {
    let selected = this.element.find("input[type='radio'][name$='[release_varies]']:checked")

    switch(selected.val()) {
      // If before specific date selected
      case "before":
        this.enableReleaseVariesDate();
        this.disableReleaseVariesSelect();
        break;

      // If embargo option selected
      case "embargo":
        this.disableReleaseVariesDate();
        this.enableReleaseVariesSelect();
        break;

      // Nothing selected
      default:
        this.disableReleaseVariesDate();
        this.disableReleaseVariesSelect();
    }
  }

  // Disable ALL sub-options under "Varies"
  disableReleaseVariesOptions() {
    this.disableReleaseVariesRadio()
    this.disableReleaseVariesSelect()
    this.disableReleaseVariesDate()
  }

  // Disable all radio inputs under the release "Varies" option
  disableReleaseVariesRadio() {
    this.element.find("#release-varies input[type='radio'][name$='[release_varies]']").prop("disabled", true)
  }

  // Enable all radio inputs under the release "Varies" option
  enableReleaseVariesRadio() {
    this.element.find("#release-varies input[type='radio'][name$='[release_varies]']").prop("disabled", false)
  }

  // Disable selectbox next to release "Varies" embargo option
  disableReleaseVariesSelect() {
    this.element.find("#release-varies select[name$='[release_embargo]']").prop("disabled", true)
  }

  // Enable selectbox next to release "Varies" embargo option
  enableReleaseVariesSelect() {
    this.element.find("#release-varies select[name$='[release_embargo]']").prop("disabled", false)
  }

  // Disable date input field next to release "Varies" before option
  disableReleaseVariesDate() {
    this.element.find("#release-varies input[type='date'][name$='[release_date]']").prop("disabled", true)
  }

  // Enable date input field next to release "Varies" before option
  enableReleaseVariesDate() {
    this.element.find("#release-varies input[type='date'][name$='[release_date]']").prop("disabled", false)
  }

  // Disable date input field next to release "Fixed" option
  disableReleaseFixedDate() {
    this.element.find("#release-fixed input[type='date'][name$='[release_date]']").prop("disabled", true)
  }

  // Enable date input field next to release "Fixed" option
  enableReleaseFixedDate() {
    this.element.find("#release-fixed input[type='date'][name$='[release_date]']").prop("disabled", false)
  }

  // Disable visibility "Restricted" option (not valid for embargoes)
  disableVisibilityRestricted() {
    this.element.find("input[type='radio'][name$='[visibility]'][value='restricted']").prop("disabled", true)
  }

  // Enable visibility "Restricted" option
  enableVisibilityRestricted() {
    this.element.find("input[type='radio'][name$='[visibility]'][value='restricted']").prop("disabled", false)
  }

  // Check whether the browser supports input[type="date"]
  isDateSupported() {
    let input = document.createElement('input');
    input.setAttribute('type', 'date');
    return (input.type === 'date');
  }

  // Change date form on from yyyy-mm-dd to mm/dd/yyyy on display
  formatDateOnLoad() {
    if(!this.isDateSupported()) {
      // Detect yyyy-mm-dd format
      const regex = /^\d{4}[./-]\d{2}[./-]\d{2}$/;

      // Get all the input fields
      let $inputs = this.element.find(':input');

      $inputs.each(function() {
        if($(this).attr('type') === 'date') {
          let value = $(this).val();
          if(value.match(regex)) {
            const [yyyy, mm, dd] = value.split('-');
            $(this).val(mm + '/' + dd + '/' + yyyy);
          }
        }
      });
    }
  }

  // Change date format from mm/dd/yyyy to yyyy-mm-dd on form submit
  validateEmbargoDate() {
    if(!this.isDateSupported()) {
      // Detect mm/dd/yyyy format
      const regex = /^\d{2}[./-]\d{2}[./-]\d{4}$/;

      let $form = this.element.find('form');
      $form.on('submit', function() {
        let data = $(this).serializeArray();
        let releaseDate = data.find(item => item.name === 'permission_template[release_date]');

        if(releaseDate && releaseDate.value.match(regex)) {
          const [mm, dd, yyyy] = releaseDate.value.split('/');
          releaseDate.value = yyyy + '-' + mm + '-' + dd;
        }

        // Request with modified data
        $.ajax({
            type: "POST",
            url: $(this).attr('action'),
            data: data
        });
        return false; // prevents normal behaviour
      });
    }
  }
}
