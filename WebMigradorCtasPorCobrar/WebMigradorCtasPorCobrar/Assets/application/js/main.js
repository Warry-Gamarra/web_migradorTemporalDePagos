
$(document).on('ready', function () {
    $('#btnsubmit').removeClass('disabled');
    $('#btnCancel').removeClass('disabled');
});

function Load() {
    $('#loading').show();
    $('#btnsubmit').addClass('disabled');
    $('#btnCancel').addClass('disabled');
    $('#modal-container').attr('data-backdrop', 'static');
}

function Stop() {
    $('#loading').hide();
    $('#btnCancel').removeClass('disabled');
    $('#modal-container').removeAttr('data-backdrop');
}

function Submited() {
    var submited = parseInt($("#submited").val());
    $("#submited").val(submited + 1);
}

function Begin() {
    $('#loading').show();
    $('#div-resultado').html('');
    $('#div-resultado').hide();
}

function onComplete() {
    $('#loading').hide();
    $('#div-resultado').show();
}

function FormatearNumero(number, decimals = 2, round = true) {
    if (isNaN(number) || number.lenght == 0) number = 0;

    if (round) {
        return parseFloat(number).toFixed(decimals);
    }
    else {
        let arrStr = number.split('.');
        if (decimals > 0 && arrStr.lenght > 1) {
            number = arrStr[0] + '.' + arrStr[1].substring(0, decimals);
            return parseFloat(number);
        }
        else {
            return parseFloat(arrStr[0]);
        }
    }
}

function htmlDecode(input) {
    var element = document.createElement('textarea');
    element.innerHTML = input;
    return element.value;
}



function ChangeStateReloadPage(RowID, B_habilitado, ActionName) {
    var parametros = {
        RowID: RowID,
        B_habilitado: B_habilitado
    };
    $.ajax({
        cache: false,
        url: ActionName,
        type: "POST",
        data: parametros,
        dataType: "json",
        beforeSend: function () {
            $('#loader' + RowID).css("display", "inline");
        },
        success: function (data) {
            $('#loader' + RowID).css("display", "none");
            if (data['Value']) {
                $('#td' + RowID).html(data['Message']);

                location.reload();
            }
            else {
                toastr.warning(data['Message']);
            }
        },
        error: function () {
            $('#loader' + RowID).css("display", "none");

            toastr.error("No se pudo actualizar el estado. Intente nuevamente en unos segundos.<br /> Si el problema persiste comuníquese con el área de soporte de la aplicación.");
        }
    });
}

function ChangeState(RowID, B_habilitado, ActionName) {
    var parametros = {
        RowID: RowID,
        B_habilitado: B_habilitado
    };
    $.ajax({
        cache: false,
        url: ActionName,
        type: "POST",
        data: parametros,
        dataType: "json",
        beforeSend: function () {
            $('#loader' + RowID).css("display", "inline");
        },
        success: function (data) {
            $('#loader' + RowID).css("display", "none");
            if (data['Value']) {
                if (B_habilitado) {
                    $('#td' + RowID).html(`<button type="submit" class="btn btn-xs btn-secondary" onclick="ChangeState(${ RowID }, false, '${ ActionName }');"><i class="fa fa-minus-circle">&nbsp;</i><span class="d-none d-md-inline-block">Deshabilitado</span></button>`);
                }
                else {
                    $('#td' + RowID).html(`<button type="submit" class="btn btn-xs btn-success" onclick="ChangeState(${ RowID }, true, '${ ActionName }');"><i class="fa fa-check-circle">&nbsp;</i><span class="d-none d-md-inline-block">Habilitado</span></button>`);
                }

                toastr.succees(data['Message']);
            }
            else {
                toastr.warning(data['Message']);
            }
        },
        error: function () {
            $('#loader' + RowID).css("display", "none");

            toastr.error("No se pudo actualizar el estado. Intente nuevamente en unos segundos.<br /> Si el problema persiste comuníquese con el área de soporte de la aplicación.");
        }
    });
}
