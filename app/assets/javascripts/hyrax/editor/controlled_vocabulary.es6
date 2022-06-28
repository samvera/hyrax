//= require handlebars

import { FieldManager } from 'hydra-editor/field_manager'
import Handlebars from 'handlebars'
import Autocomplete from 'hyrax/autocomplete'

export default class ControlledVocabulary extends FieldManager {

  constructor(element, paramKey) {
      let options = {
        /* callback to run after add is called */
        add:    null,
        /* callback to run after remove is called */
        remove: null,

        controlsHtml:      '<span class=\"input-group-btn field-controls\">',
        fieldWrapperClass: '.field-wrapper',
        warningClass:      '.has-warning',
        listClass:         '.listing',
        inputTypeClass:    '.controlled_vocabulary',

        addHtml:           '<button type=\"button\" class=\"btn btn-link add\"><span class=\"fa fa-plus\"></span><span class="controls-add-text"></span></button>',
        addText:           'Add another',

        removeHtml:        '<button type=\"button\" class=\"btn btn-link remove\"><span class=\"fa fa-minus\"></span><span class="controls-remove-text"></span> <span class=\"sr-only\"> previous <span class="controls-field-name-text">field</span></span></button>',
        removeText:         'Remove',

        labelControls:      true,
      }
      super(element, $.extend({}, options, $(element).data()))
      this.paramKey = paramKey
      this.fieldName = this.element.data('fieldName')
      this.searchUrl = this.element.data('autocompleteUrl')
  }

  // Overrides FieldManager, because field manager uses the wrong selector
  // addToList( event ) {
  //         event.preventDefault();
  //         let $listing = $(event.target).closest('.multi_value').find(this.listClass)
  //         let $activeField = $listing.children('li').last()
  //
  //         if (this.inputIsEmpty($activeField)) {
  //             this.displayEmptyWarning();
  //         } else {
  //             this.clearEmptyWarning();
  //             $listing.append(this._newField($activeField));
  //         }
  //
  //         this._manageFocus()
  // }

  // Overrides FieldManager in order to avoid doing a clone of the existing field
  createNewField($activeField) {
      let $newField = this._newFieldTemplate()
      this._addBehaviorsToInput($newField)
      this.element.trigger("managed_field:add", $newField);
      return $newField
  }

  /* This gives the index for the editor */
  _maxIndex() {
      return $(this.fieldWrapperClass, this.element).length
  }

  // Overridden because we always want to permit adding another row
  inputIsEmpty(activeField) {
      return false
  }

  _newFieldTemplate() {
      let index = this._maxIndex()
      let rowTemplate = this._template()
      let controls = this.controls.clone()//.append(this.remover)
      let row =  $(rowTemplate({ "paramKey": this.paramKey,
                                 "name": this.fieldName,
                                 "index": index,
                                 "class": "controlled_vocabulary" }))
                  .append(controls)
      return row
  }

  get _source() {
      return "<li class=\"field-wrapper input-group input-append\">" +
        "<input class=\"string {{class}} optional form-control {{paramKey}}_{{name}} form-control multi-text-field\" name=\"{{paramKey}}[{{name}}_attributes][{{index}}][hidden_label]\" value=\"\" id=\"{{paramKey}}_{{name}}_attributes_{{index}}_hidden_label\" data-attribute=\"{{name}}\" type=\"text\">" +
        "<input name=\"{{paramKey}}[{{name}}_attributes][{{index}}][id]\" value=\"\" id=\"{{paramKey}}_{{name}}_attributes_{{index}}_id\" type=\"hidden\" data-id=\"remote\">" +
        "<input name=\"{{paramKey}}[{{name}}_attributes][{{index}}][_destroy]\" id=\"{{paramKey}}_{{name}}_attributes_{{index}}__destroy\" value=\"\" data-destroy=\"true\" type=\"hidden\"></li>"
  }

  _template() {
      return Handlebars.compile(this._source)
  }

  /**
  * @param {jQuery} $newField - The <li> tag
  */
  _addBehaviorsToInput($newField) {
      let $newInput = $('input.multi-text-field', $newField)
      $newInput.focus()
      this.addAutocompleteToEditor($newInput)
      this.element.trigger("managed_field:add", $newInput)
  }

  /**
  * Make new element have autocomplete behavior
  * @param {jQuery} input - The <input type="text"> tag
  */
  addAutocompleteToEditor(input) {
    var autocomplete = new Autocomplete()
    autocomplete.setup(input, this.fieldName, this.searchUrl)
  }

  // Overrides FieldManager
  // Instead of removing the line, we override this method to add a
  // '_destroy' hidden parameter
  removeFromList( event ) {
      event.preventDefault()
      let field = $(event.target).parents(this.fieldWrapperClass)
      field.find('[data-destroy]').val('true')
      field.hide()
      this.element.trigger("managed_field:remove", field)
  }
}
