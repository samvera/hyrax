export default class SelectWorkType {
  /**
   * Initializes the class in the context of an individual table element
   * @param {jQuery} element the table element that this class represents
   */
  constructor(element) {
      this.$element = element;
      this.target = element.data('target')
      this.modal = $(this.target)
      this.form = this.modal.find('form.new-work-select')

      // launch the modal.
      element.on('click', (e) => {
          e.preventDefault()
          this.modal.modal()
          // ensure the type is set for the last clicked element
          // type is either "batch" or "single" (work)
          this.type = element.data('create-type')
          // add custom routing logic when the modal is shown
          this.form.on('submit', this.routingLogic.bind(this))
      });

      // remove the routing logic when the modal is hidden
      this.modal.on('hide.bs.modal', (e) => {
          this.form.unbind('submit')
      });
  }

  // when the form is submitted route to the correct location
  routingLogic(e) {
      e.preventDefault()
      if (this.destination() === undefined)
        return false
      // get the destination from the data attribute of the selected radio button
      window.location.href = this.destination()
  }

  // Each input has two attributes that contain paths, one for the batch and one
  // for a single work.  So, given the value of 'this.type', return the appropriate
  // path.
  destination() {
      return this.form.find('input[type="radio"]:checked').data(this.type)
  }
}
