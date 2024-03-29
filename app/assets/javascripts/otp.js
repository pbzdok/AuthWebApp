$("#user_totp_activated").change(function () {
    if (this.checked) {
        $('#otp_modal').modal();
    }
});

$('#otp_modal').on('hide.bs.modal', function () {
    $('#user_totp_activated').prop("checked", false);
});

$('#verify_top_btn').on('click', function () {
    const id = location.pathname.split("/")[2];
    let totp = document.getElementById("otp").value;
    $.ajax({
        type: "GET",
        url: `/users/${id}/verify_otp.json`,
        data: {
            user: {
                totp: totp
            }
        },
        dataType: "json",
        success: function (data) {
            if (data["totp_valid"]) {
                $('#otp_modal').modal('hide');
                $("#user_totp_activated").prop("checked", true);
                alert("TOTP successfully confirmed!")
            } else {
                document.getElementById("otp").style.borderColor = "red";
                alert("TOTP wrong!");
                $("#user_totp_activated").prop("checked", false);
            }
        },
        error: function (data) {
            console.error("Asynchronous request failed!");
            console.log(data)
        }
    });
});

$('#sign_button_totp').on('click', function () {
    $('#totp_authentication_modal').modal();
});

$('#totp_authenticate_otp_btn').on('click', function () {
    const message_id = location.pathname.split("/")[2];
    let user_id = document.getElementById("user_id").innerText;
    let totp = document.getElementById("otp").value;
    $.ajax({
        type: "GET",
        url: `/users/${user_id}/verify_otp.json`,
        data: {
            user: {
                totp: totp
            }
        },
        dataType: "json",
        success: function (data) {
            if (data["totp_valid"]) {
                $('#totp_authentication_modal').modal('hide');
                alert("TOTP successfully confirmed!");
                $.ajax({
                    type: "PATCH",
                    url: `/messages/${message_id}`,
                    data: {
                        message: {
                            authenticated: true,
                            authentication_token : data["authentication_token"]
                        }
                    }
                })
            } else {
                document.getElementById("otp").style.borderColor = "red";
                alert("TOTP wrong!");
            }
        },
        error: function (data) {
            console.error("Asynchronous request failed!");
            console.log(data)
        }
    });
});

