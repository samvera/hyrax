/**
 * Generic helper utilities for processing Collection and Collection Type editing
 * @type {Class}
 */
export default class CollectionUtilities {
  constructor() {
    this.addParticipantsInputValidator = new AddParticipantsInputValidator();
    this.addParticipants = new AddParticipants();
  }
}

class AddParticipants {
  /**
   * Notes:
   This is a workaround for a scoping issue with 'simple_form' and nested forms in the
   'Edit Collections' partials.  All tabs were wrapped in a 'simple_form'. Nested forms, for example inside a tab partial,
   have behaved erratically, so the pattern has been to remove nested form instances for relatively non-complex forms
   and replace with AJAX requests.  For this instance of Add Sharing > Add user and Add group, seem more complex in how
   the form is built from '@form.permission_template', so since it's not working, but the form is already built, this
   code listens for a click event on the nested form submit button, prevents Default submit behavior, and manually makes
   the form post.
   * @param  {jQuery event} e jQuery event object
   * @return {void}
   */
  handleAddParticipants(e) {
    e.preventDefault();
    const { wrapEl, urlFn } = e.data;
    // This is a callback, because some POST urls might depend on dynamic id variables
    // Send the e event object back and construct any values needed
    const url = urlFn(e);
    const $wrapEl = $(e.target).parents(wrapEl);

    if ($wrapEl.length === 0) {
      return;
    }
    // Get all input values to send in the upcoming POST
    const serialized = $wrapEl.find(':input').serialize();
    if (serialized.length === 0) {
      return;
    }

    $.ajax({
      type: 'POST',
      url: url,
      data: serialized
    })
      .done(function(response) {
        // Success handler here, possibly show alert success if page didn't reload?
      })
      .fail(function(err) {
        console.error(err);
      });
  }
}

/**
 * Handle enabling/disabling "Add" button for adding a user or group when editing a Collection
 * or Collection Type.  Determines whether editable inputs have been filled out or not, then sets button state.
 * @type: {Class}
 */
class AddParticipantsInputValidator {
  /**
   * Check that regular inputs have a non-empty input value
   * @param  {jQuery object} $inputs Inputs which are editable by the user
   * @return {boolean}  Do all inputs passed in have values?
   */
  checkInputsPass($inputs) {
    let inputsPass = true;

    $inputs.each(function(i) {
      if ($(this).val() === '') {
        inputsPass = false;
        return false;
      }
    });
    return inputsPass;
  }

  /**
   * Checks that the select2 input (if it exists) has a non-default value
   * @param  {object} context jQuery $(this) context object
   * @return {boolean} Whether a select2 input has a non-default value, or doesn't exist
   */
  checkSelect2Pass(context) {
    const $select2 = context.find('.select2-container');
    // No select2 element present, so it passes by default
    if ($select2.length === 0) {
      return true;
    }
    const $placeholder = $select2.siblings('[placeholder]');
    const placeholderValue = $placeholder.attr('placeholder');
    const chosenValue = $select2.find('.select2-chosen').text();

    return placeholderValue !== chosenValue;
  }

  /**
   * Handle disabled button state for the 'Add' button for Collections or
   * Collection Type > Edit > Sharing or Participants tab Add Sharing or Add Partipants section
   * @param  {object} event jQuery event object
   * @param {string} event.data.buttonSelector jQuery selector string for row's button
   * @param {string} event.data.inputsWrapper jQuery selector string for the wrapping selector class which holds inputs
   * @return {void}
   */
  handleWrapperContentsChange(event) {
    const { buttonSelector, inputsWrapper } = event.data;
    const $inputsWrapper = $(event.target).parents(inputsWrapper);
    // Get regular inputs for the row
    const $inputs = $inputsWrapper.find('.form-control');
    const $addButton = $inputsWrapper.find(buttonSelector);
    const inputsPass = this.checkInputsPass($inputs);
    const select2Pass = this.checkSelect2Pass($inputsWrapper);

    $addButton.prop('disabled', !(inputsPass && select2Pass));
  }
}
