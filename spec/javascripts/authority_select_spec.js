describe('authority select', () => {   
    beforeEach(() =>  {
	setFixtures(`
<input class="string multi_value required form-control generic_work_creator form-control multi-text-field ui-autocomplete-input" data-autocomplete-url="/authorities/search/loc/names" data-autocomplete="creator" required="required" aria-required="true" name="generic_work[creator][]" value="" id="generic_work_creator" aria-labelledby="generic_work_creator_label" type="text" autocomplete="off">
<select class="form-control select required generic_work_creator" data-authority-select="generic_work_creator" required="required" aria-required="Select an authority" name="generic_work[creator]" id="generic_work_creator"><option value="/authorities/search/loc/names">LOC Names</option>
<option value="/authorities/search/assign_fast/all">FAST</option></select>
`)
    })
    
    it('should change the data-autocomplete-url when you select an authority', () => {
        Hyrax.authoritySelect()
	$('select.generic_work_creator').val('/authorities/search/assign_fast/all').change()
	expect($('input.generic_work_creator').data('autocomplete-url')).toEqual('/authorities/search/assign_fast/all')
    })
})
