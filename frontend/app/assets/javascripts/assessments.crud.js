//= require subrecord.crud
//= require form

function AssessmentsForm($form) {
    this.$form = $form;

    this.$form.find(".linker:not(.initialised)").linker();
    this.setupRatingTable();
};



AssessmentsForm.prototype.setupRatingTable = function() {
    var self = this;
    var $table = self.$form.find('#rating_attributes_table');

    self.setupRatingNotes($table);

    $table.on('click', 'td', function(event) {
        if ($(this).find(':radio').length > 0) {
            var $radio = $(this).find(':radio');

            if ($radio.is(':not(:checked)')) {
                $radio.prop('checked', true);
            }
        }

        return true;
    });
};


AssessmentsForm.prototype.setupRatingNotes = function($table) {
    var self = this;

    $table.on('click', '.assessment-add-rating-note', function(event) {
        event.preventDefault();

        var $ratingRow = $(this).closest('tr');
        //$ratingRow.find('td:first').attr('rowspan', 2);

        var $noteRow = $ratingRow.next();
        $noteRow.find('textarea').prop('disabled', false);

        $noteRow.show();

        $(this).hide();
        $(this).siblings('.assessment-remove-rating-note').show();
    });

    $table.on('click', '.assessment-remove-rating-note', function(event) {
        event.preventDefault();

        var $ratingRow = $(this).closest('tr');
        //$ratingRow.find('td:first').attr('rowspan', 1);

        var $noteRow = $ratingRow.next();
        $noteRow.find('textarea').prop('disabled', true);

        $noteRow.hide();

        $(this).hide();
        $(this).siblings('.assessment-add-rating-note').show();
    });
};


$(document).ready(function() {
    new AssessmentsForm($('form#assessment_form'));
});