export default class SortAndPerPage {
  /**
   * Initializes the class in the context of an individual select element,
   * and bind its change event to submit the form it is contained within.
   * @param {jQuery} element the select element that this class represents
   */
  constructor(element) {
      this.form = element.parents('form')[0];

      // submit the form to cause the page to render
      element.on('change', (e) => {
          this.form.submit();
      });
  }
}
