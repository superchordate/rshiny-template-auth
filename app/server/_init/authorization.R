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

    # skip the check if the app is not using recaptcha.
    if(!auth_methods$invisible_recaptcha) return(TRUE)

    # Before proceeding, you must authenticate with reCAPTCHA. API requests to reCAPTCHA will fail until authentication steps are complete.
    # See https://cloud.google.com/recaptcha/docs/authentication.
    if(Sys.getenv("RECAPTCHA_API_KEY") == "") stop('RECAPTCHA_API_KEY not set in .env file. Please see the README for setup instructions.')
    if(Sys.getenv("PUBLIC_RECAPTCHA_SITE_KEY") == "") stop('PUBLIC_RECAPTCHA_SITE_KEY not set in .env file. Please see the README for setup instructions.')

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
        session$sendCustomMessage('user_warning', paste0('Failed to send confirmation email. Email confirmation is required. Please try again. ', result$error$message))
        return()
    }
      
    if(alert) session$sendCustomMessage('user_alert', 'Please confirm your email address. Confirmation email has been sent.')
}

observeEvent(input$user_logout, {
    authorized(FALSE)
})

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

    # this part only applies if MFA is required.
    if(auth_methods$mfa_sms){

        # if a user has set up MFA, google will not send an idToken back until they have successfully authenticated with MFA.
        # however, it wil send a token before they enroll. so we have to check here to confirm enrollment.
        # if MFA is required, confirm the user has it set up. if they haven't, they aren't authorized.
        if(is.null(user$mfaInfo) || length(user$mfaInfo) == 0){
            session$sendCustomMessage('show_mfa', 'show_mfa')
            not_authorized()
            return()
        }

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

    if(!auth_methods$allow_register_new_user){
        session$sendCustomMessage('user_error', 'New user registration is not allowed.')
        not_authorized()
        return()
    }

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
    session$sendCustomMessage('user_success', list(message = 'A verification email has been sent. Please click the link in the email to verify your email address.', doreload = TRUE))
    updateTextInput(session, "new_user_register", value = NULL)
    authorized(FALSE)

})

observeEvent(input$mfa_verification, {

  if(!auth_methods$mfa_sms){
    session$sendCustomMessage('user_error', 'MFA verification was requested but this application does not have MFA enabled.')
    not_authorized()
    return()
  }
  
  # validate the access token.
  verified_user = verify_idToken(input$mfa_verification$user$stsTokenManager$accessToken)
  if(is.null(verified_user) || is.null(verified_user$email)){
    not_authorized()
    return()
  }
  
  # if the user's email has not been verified, send the user a confirmation email.
  if(!input$mfa_verification$user$emailVerified){
    send_confirmation(input$user_login[1])
    not_authorized()
    return()
  }
  
  # validate the MFA user is the same as the logged in user.
  if(verified_user$email != input$mfa_verification$user$email){
    session$sendCustomMessage('user_error', 'MFA verification error.')
    not_authorized()
    return()
  }
  
  # by now, we've validate the mfa verification (which includes the user information) and can authorize the user.
  session$sendCustomMessage('stop_spinner', 'close_spinner')
  authorized(TRUE)

})