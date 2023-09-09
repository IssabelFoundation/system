function prepararBoton(s)
{
    $("#" + s).iButton({
        labelOn:    "On",
        labelOff:   "Off",
        change: function ($input) {
            var arrAction = {
                menu:        'betachannel',
                rawmode:     'yes',
                action:      'update_' + s
            };
            arrAction["new_" + s] = ($input.is(":checked") ? 1 : 0)
            if (arrAction["new_" + s] != $("#old" + s).val()) {
                $.post('index.php?menu=betachannel&rawmode=yes', arrAction,
                function (resultado) {
                    var arrData = resultado['message'];
                    if (arrData['result']) {
                        // Recordar nuevo valor
                        $("#old" + s).val(($input.is(":checked") ? 1 : 0));
                    } else {
                        // Restaurar valor anterior
                        if ($("#old" + s).val() == 1) {
                            $("#" + s).prop("checked", true);
                        } else {
                            $("#" + s).prop("checked", false);
                        }
                    }

                    // Mostrar mensajes
                    $("#message_error").remove();
                    if (document.getElementById("neo-contentbox-maincolumn")) {
                        var message= "<div class='div_msg_errors' id='message_error'>" +
                                "<div style='float:left;'>" +
                                "<b style='color:red;'>"+arrData['message_title']+"</b>" +
                                "</div>" +
                                "<div style='text-align:right; padding:5px'>" +
                                "<input type='button' onclick='hide_message_error();' value='"+arrData['button_title']+"'/>" +
                                "</div>" +
                                "<div style='position:relative; top:-12px; padding: 0px 5px'>" +
                                arrData['message'] +
                                "</div>" +
                            "</div>";
                        $(".neo-module-content:first").prepend(message);
                    } else if(document.getElementById("elx-blackmin-content")) {
                        var message = "<div id='message_error' class='ui-state-highlight ui-corner-all'>" +
                                  "<p>" +
                                  "<span style='float: left; margin-right: 0.3em;' class='ui-icon ui-icon-info'></span>" +
                                  "<span id='issabel-callcenter-info-message-text'>"+ arrData['message_title'] + arrData['message'] +"</span>" +
                                  "</p>" +
                              "</div>";
                        $("#elx-blackmin-content").prepend(message);
                    } else {
                        var message= "<div style='background-color: rgb(255, 238, 255);' id='message_error'><table width='100%'><tr><td align='left'><b style='color:red;'>" +
                              arrData['message_title'] + "</b>" + arrData['message'] + "</td> <td align='right'><input type='button' onclick='hide_message_error();' value='" +
                              arrData['button_title']+ "'/></td></tr></table></div>";
                        $("body > table > tbody > tr > td").prepend(message);
                    }
                });
            }
        }
    });
}

$(document).ready(function () {
    prepararBoton("beta_channel_status");
});
