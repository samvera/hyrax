function batch_edit_init () {

    // initialize popover helpers
    $("a[rel=popover]").popover({ html: true });

    function deserialize(Params) {
        var Data = Params.split("&");
        var i = Data.length;
        var Result  = {};
        while (i--) {
            var Pair = decodeURIComponent(Data[i]).split("=");
            var key = Pair[0];
            var val = Pair[1];
            if (Result[key] != null) {
                if(!$.isArray(Result[key])) Result[key] = [Result[key]];
                Result[key].push(val);
            } else
                Result[key] = val;
        }
        return Result;
    }

    var ajaxManager = (function () {
        var requests = [];
        var running = false;
        return {
            addReq: function (opt) {
                requests.push(opt);
            },
            removeReq: function (opt) {
                if ($.inArray(opt, requests) > -1)
                    requests.splice($.inArray(opt, requests), 1);
            },
            runNow: function () {
                clearTimeout(this.tid);
                if (!running) {
                    this.run();
                }
            },
            run: function () {
                running = true;
                var self = this;

                if (requests.length) {

                    // combine data from multiple requests
                    if (requests.length > 1) {
                      requests = this.combine_requests(requests);
                    }

                    requests = this.setup_request_complete(requests);
                    $.ajax(requests[0]);
                } else {
                    self.tid = setTimeout(function () {
                        self.run.apply(self, []);
                    }, 500);
                    running = false;
                }
            },
            stop: function () {
                requests = [];
                clearTimeout(this.tid);
            },
            setup_request_complete: function (requests) {
                oriComp = requests[0].complete;

                requests[0].complete = [ function (e) {
                    req = requests.shift();
                    if (typeof req.form === 'object') {
                        for (f in req.form) {
                            form_id = form[f];
                            after_ajax(form_id);
                        }
                    }
                    this.tid = setTimeout(function () {
                        ajaxManager.run.apply(ajaxManager, []);
                    }, 50);
                    return true;
                }];
                if (typeof oriComp === 'function') requests[0].complete.push(oriComp);
                return requests;
            },
            combine_requests: function (requests) {
                var data = deserialize(requests[0].data.replace(/\+/g, " "));
                form = [requests[0].form]
                for (var i = requests.length - 1; i > 0; i--) {
                    req = requests.pop();
                    adata = deserialize(req.data.replace(/\+/g, " "));

                    for (key in  Object.keys(adata)) {
                        curKey = Object.keys(adata)[key];
                        if (curKey.slice(0, 12) == "generic_file") {
                            data[curKey] = adata[curKey];
                            form.push(req.form);
                        }
                    }
                }
                requests[0].data = $.param(data);
                requests[0].form = form;
                return requests;
            }
        };
    }());


    ajaxManager.run();

    function formButtons(form_id) {
        return $('#' + form_id + ' .btn')
    }

    function formFields(form_id) {
        return $('#' + form_id + ' .form-group > *')
    }

    function formRightPanel(form_id) {
        return $('#' + form_id + ' .form-group')
    }

    function disableForm(form_id) {
        formButtons(form_id).attr("disabled", "disabled");
        formRightPanel(form_id).addClass("loading");
        formFields(form_id).addClass('invisible')
    }

    function enableForm(form_id) {
        formButtons(form_id).removeAttr("disabled");
        formRightPanel(form_id).removeClass("loading");
        formFields(form_id).removeClass('invisible')
    }

    function after_ajax(form_id) {
        var key = form_id.replace("form_", "");
        $("#status_" + key).html("Changes Saved");
        enableForm(form_id);
    }

    function before_ajax(form_id) {
        disableForm(form_id);
    }

    function runSave(e) {
        e.preventDefault();
        var button = $(this);
        var form = button.closest('form');
        var form_id = form[0].id;
        before_ajax(form_id);

        ajaxManager.addReq({
            form: form_id,
            queue: "add_doc",
            url: form.attr("action"),
            dataType: "json",
            type: form.attr("method").toUpperCase(),
            data: form.serialize(),
            complete: function (e) {
                after_ajax(form_id);
                if (e.status == 200) {
                    eval(e.responseText);
                } else {
                    alert("Error!  Status: " + e.status);
                }
            }
        });
        setTimeout(ajaxManager.runNow(), 100);
    }

    $("#permissions_save").click(runSave);
    $(".field-save").click(runSave);
}



// turbolinks triggers page:load events on page transition
// If app isn't using turbolinks, this event will never be triggered, no prob.
$(document).on('page:load', function() {
    batch_edit_init();
});

$(document).ready(function() {
    batch_edit_init();
});
