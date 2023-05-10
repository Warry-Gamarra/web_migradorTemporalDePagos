
$(document).on("ready", function () {
    $('#date .input-group.date').datepicker({
        todayBtn: 'linked',
        language: 'es',
        format: 'dd/MM/yyyy',
        autoclose: true,
        startDate: '-0d',
        weekStart: 0,
        orientation: 'top left',
        daysOfWeekDisabled: '0,6',
        calendarWeeks: true,
    });

    $('#datepicker .input-daterange').datepicker({
        todayBtn: 'linked',
        language: 'es',
        format: 'dd/MM/yyyy',
        autoclose: true,
        weekStart: 0,
        orientation: 'top left',
        daysOfWeekDisabled: '0,6',
        calendarWeeks: true
    });

    $('#monthpicker .input-daterange').datepicker({
        format: "MM/yyyy",
        endDate: "+0y",
        autoclose: true,
        minViewMode: 1,
        language: "es",
        multidate: false
    });

    $('#yearpicker .input-daterange').datepicker({
        format: "yyyy",
        endDate: "+0y",
        autoclose: true,
        minViewMode: 2,
        language: "es",
        multidate: false
    });

    $('#multidatepicker').datepicker({
        language: "es",
        multidate: true,
        format: 'dd/MM/yyyy',
        stratView: 1,
        startDate: '-0d',
        weekStart: 0,
        multidateSeparator: ', ',
        orientation: "top auto",
        daysOfWeekDisabled: '0,6',
        calendarWeeks: true,

    });

    $('#multidatepicker').on("changeDate", function () {
        $('#fechas').val(
            $('#multidatepicker').datepicker('getFormattedDate')
        );
    });

    $('.timepicker24h').timepicker({
        showMeridian: false,
        showSeconds: true,
        minuteStep: 5,
        secondStep: 15,
        showInputs: false
    });

    $('.timepicker12h').timepicker({
        showSeconds: true,
        minuteStep: 5,
        secondStep: 15,
        showInputs: false
    });

});