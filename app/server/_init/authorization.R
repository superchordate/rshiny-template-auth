# user verification.
authorized = reactiveVal(NULL)

verify_idToken = function(idToken){

    if(idToken == 'logout'){
        authorized(FALSE)
        return()
    }

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

observeEvent(input$idToken, {

    verified_user = verify_idToken(input$idToken)

    if(!is.null(verified_user) && !is.null(verified_user$email)){
        # session$sendCustomMessage('verified_user', TRUE)
        authorized(TRUE)
    } else {
        authorized(FALSE)
    }

})

# observeEvent(input$mfa_verification, {
  
#     verified_user_mfa = verify_idToken(input$mfa_verification$`_tokenResponse`$idToken)
    
#     #TODO how to verify MFA on server. 

#     if(!is.null(verified_user_mfa) && !is.null(verified_user_mfa$email)){
#         authorized(TRUE)
#     } else {
#         authorized(FALSE)
#     }

# })

# reCAPTCHA verification.
# this is triggered when the user clicks "Register as New User".
# requires invisible_recaptcha = TRUE (global.R) and reCAPTCHA setup steps in README.
observeEvent(input$recaptcha_token, {

    if(is.null(input$recaptcha_token) || input$recaptcha_token == '') return()

    # if recaptcha is not enabled, send a passing score.
    if(!auth_methods$invisible_recaptcha){
        session$sendCustomMessage('recaptcha_score', 1)
        return()
    }

    # Before proceeding, you must authenticate with reCAPTCHA. API requests to reCAPTCHA will fail until authentication steps are complete.
    # See https://cloud.google.com/recaptcha/docs/authentication.
    response = POST(
        url = paste0("https://recaptchaenterprise.googleapis.com/v1/projects/testauth-450202/assessments?key=", Sys.getenv("RECAPTCHA_API_KEY")),
        body = toJSON(list(event = list(
            "token" = input$recaptcha_token,
            "expectedAction" = "REGISTER",
            "siteKey" = Sys.getenv("PUBLIC_RECAPTCHA_SITE_KEY")
        )), auto_unbox = TRUE),
        encode = "json",
        content_type_json()
    )

    result = content(response, "parsed")
    score = result$riskAnalysis$score
    
    # client JS will handle the score, see app/templates/login.html.
    session$sendCustomMessage('recaptcha_score', score)

})