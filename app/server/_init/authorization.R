# user verification.
authorized = reactiveVal(NULL)

verify_idToken = function(idToken){

    # extract information from token. 
    header = jwt_split(idToken)$header

    # verify the token using the Firebase public key.
    certs = fromJSON('https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com')
    #certs = fromJSON('https://www.googleapis.com/oauth2/v1/certs')
    public_key = certs[[header$kid]]

    # validate the results. 
    if(header$alg != 'RS256'){
        warning('Wrong algorithm.')
        authorized(FALSE)
        return()
    }

    if(is.null(public_key)){
        warning("Invalid key ID in token.")
        authorized(FALSE)
        return()
    }

    # get the decoded/validated information. 
    verified_token = jwt_decode_sig(idToken, pubkey = public_key)
    exp = as.POSIXct(verified_token$exp, origin = "1970-01-01", tz = "UTC")

    if(exp < Sys.time()){
        warning('Expired token.')
        authorized(FALSE)
        return()
    }

    return(list(email = verified_token$email))

}

verify_recaptcha = function(recaptcha_token){

    # Before proceeding, you must authenticate with reCAPTCHA. API requests to reCAPTCHA will fail until authentication steps are complete.
    # See https://cloud.google.com/recaptcha/docs/authentication.

    response = POST(
        url = paste0("https://recaptchaenterprise.googleapis.com/v1/projects/testauth-450202/assessments?key=", Sys.getenv("RECAPTCHA_API_KEY")),
        body = toJSON(list(event = list(
            "token" = recaptcha_token,
            "expectedAction" = "REGISTER",
            "siteKey" = Sys.getenv("PUBLIC_RECAPTCHA_SITE_KEY")
        )), auto_unbox = TRUE),
        encode = "json",
        content_type_json()
    )

    result = content(response, "parsed")
    score = result$riskAnalysis$score

    return(TRUE)
    if(score < 0.5){
        warning('reCAPTCHA score too low.')
        return(FALSE)
    } else {
        return(TRUE)
    }

}

send_confirmation = function(idToken, alert = TRUE){
      
    response = POST(
        url = paste0("https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=", Sys.getenv("PUBLIC_FIREBASE_API_KEY")),
        body = toJSON(list(
            requestType = "VERIFY_EMAIL",
            idToken = idToken
        ), auto_unbox = TRUE),
        encode = "json",
        content_type_json()
    )
    
    result = content(response, "parsed")
    
    if(!is.null(result$error)){
        warning(result$error$message)
        session$sendCustomMessage('user_warning', paste0('Failed to send email confirmation. Please try again. ', result$error$message))
        return()
    }
      
    if(alert) session$sendCustomMessage('user_alert', 'Please confirm your email address. Confirmation email has been sent.')
}

observeEvent(input$user_logout, {
    authorized(FALSE)
})

ok_to_show_mfa = FALSE

# anytime we set authorized to FALSE, we also want to clear the login form to allow another attempt.
not_authorized = function(){
  authorized(FALSE)
  updateTextInput(session, "user_login", value = NULL)
}

observeEvent(input$user_login, {

    if(is.null(input$user_login)) return()
    
    # verify success by validating the idToken.
    verified_user = verify_idToken(input$user_login[1])
    if(is.null(verified_user) || is.null(verified_user$email)){
      not_authorized()
      return()
    }

    # confirm the user has verified their email.
    response = POST(
        url = paste0("https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=", Sys.getenv("PUBLIC_FIREBASE_API_KEY")),
        body = toJSON(list(
            "idToken" = input$user_login[1]
        ), auto_unbox = TRUE),
        encode = "json",
        content_type_json()
    )
    user = content(response, "parsed")$users[[1]]

    # if not, send the user a confirmation email.
    if(!user$emailVerified){
        send_confirmation(input$user_login[1])
        not_authorized()
        return()
    }

    # if MFA is required, confirm the user has it set up.
    # we only check this if an initial login attempt has already been made.
    if(is.null(user$mfaInfo) || length(user$mfaInfo) == 0){
      print(ok_to_show_mfa)
      if(ok_to_show_mfa){
        session$sendCustomMessage('show_mfa', 'show_mfa')
      } else {
        ok_to_show_mfa <<- TRUE
        session$sendCustomMessage('log_user_out', 'log_user_out') # we need to log the user out to allow another attempt. 
      }
      not_authorized()
      return()
    }

    # if we got this far, the user is authorized.
    # firebase will not change auth state on a MFA user until they have successfully authenticated with MFA.
    authorized(TRUE)

})

observeEvent(input$forgot_password, {

    if(!verify_recaptcha(input$forgot_password[1])){
        session$sendCustomMessage('user_error', 'ReCAPTCHA failed. Please refresh the page and try again.')
        return()
    }

    # now that recaptcha is verified, register the user.
    response = POST(
        url = paste0("https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=", Sys.getenv("PUBLIC_FIREBASE_API_KEY")),
        body = toJSON(list(
            "requestType" = 'PASSWORD_RESET',
            "email" = input$forgot_password[2]
        ), auto_unbox = TRUE),
        encode = "json",
        content_type_json()
    )
    result = content(response, "parsed")
    
    session$sendCustomMessage('user_alert', 'If the email matches our system, a reset email has been sent.')

})

# New user registration is not included in this template (see the README section "New User Registration").
# Leaving code from my attempt to add a registration flow here, in case it does come in handy.
observeEvent(input$new_user_register, {

    if(is.null(input$new_user_register)) return()

    if(!verify_recaptcha(input$forgot_password[1])){
        session$sendCustomMessage('user_error', 'ReCAPTCHA failed. Please refresh the page and try again.')
        return()
    }

    # now that recaptcha is verified, register the user.
    # can't get this to work, so I'll send an OK message back to the client and continue there.  
    response = POST(
        url = paste0("https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=", Sys.getenv("PUBLIC_FIREBASE_API_KEY")),
        body = toJSON(list(
            "email" = input$new_user_register[2],
            "password" = input$new_user_register[3],
            "returnSecureToken" = TRUE
        ), auto_unbox = TRUE),
        encode = "json",
        content_type_json()
    )
    result = content(response, "parsed")
    
    if(!is.null(result$error)){
      warning(result$error$message)
      # we don't share the error since it can indicate if an email exists or not.
      warning(paste0('Failed to add user. Please try again. Error: ', result$error$message))
      session$sendCustomMessage('user_error', 'Failed to add user. Please try again.')
      return()
    }
    
    # verify success by validating the idToken.
    verified_user = verify_idToken(result$idToken)
    if(is.null(verified_user) || is.null(verified_user$email)){
      authorized(FALSE)
      return()
    }

    # the user will need to verify their email address before being authorized. 
    send_confirmation(result$idToken, alert = FALSE)
    session$sendCustomMessage('user_success', 'A verification email has been sent. Please click the link in the email to verify your email address.')
    updateTextInput(session, "new_user_register", value = NULL)
    authorized(FALSE)

})
