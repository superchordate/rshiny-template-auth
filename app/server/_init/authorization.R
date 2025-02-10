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

# if no user is logged in, the client will send input$idToken = "logout".
observeEvent(input$idToken, { 

    if(input$idToken == 'logout'){
        authorized(FALSE)
        return()
    }
    
    # verify success by validating the idToken.
    verified_user = verify_idToken(input$idToken)
    if(!is.null(verified_user) && !is.null(verified_user$email)){
      authorized(TRUE)
    }

})

observeEvent(input$forgot_password, {

    if(!verify_recaptcha(input$forgot_password[1])){
        session$sendCustomMessage('user_alert', 'ReCAPTCHA failed.')
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
    
    if(!is.null(result$error)){
      warning(result$error$message)
      session$sendCustomMessage('user_alert', paste0('Failed to add user. Please try again. ', result$error$message))
      return()
    }
    
    session$sendCustomMessage('user_alert', 'Reset email sent!')

})

# New user registration is not included in this template (see the README section "New User Registration").
# Leaving code from my attempt to add a registration flow here, in case it does come in handy.
observeEvent(input$new_user_register, {

    if(!verify_recaptcha(input$forgot_password[1])){
        session$sendCustomMessage('user_alert', 'ReCAPTCHA failed.')
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
      session$sendCustomMessage('user_alert', paste0('Failed to add user. Please try again. Error: ', result$error$message))
      return()
    }
    
    # verify success by validating the idToken.
    verified_user = verify_idToken(result$idToken)
    if(!is.null(verified_user) && !is.null(verified_user$email)){
      session$sendCustomMessage('user_alert', paste0('Account created successfully!'))
      authorized(TRUE)
    }

})

# # observeEvent(input$mfa_verification, {
  
# #     verified_user_mfa = verify_idToken(input$mfa_verification$`_tokenResponse`$idToken)
    
# #     #TODO how to verify MFA on server. 

# #     if(!is.null(verified_user_mfa) && !is.null(verified_user_mfa$email)){
# #         authorized(TRUE)
# #     } else {
# #         authorized(FALSE)
# #     }

# # })

# #TODO - what if user is already registered?