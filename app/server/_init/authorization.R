# user verification.
user = reactiveVal(NULL)
observeEvent(input$idToken, {

    if(is.null(input$idToken) || input$idToken == '') return()

    if(input$idToken == 'logout'){
        user('logout')
        return()
    }

    # extract information from token. 
    header = jwt_split(input$idToken)$header

    # verify the token using the Firebase public key.
    certs = fromJSON('https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com')
    #certs = fromJSON('https://www.googleapis.com/oauth2/v1/certs')
    public_key = certs[[header$kid]]

    # validate the results. 
    if(header$alg != 'RS256'){
        warning('Wrong algorithm.')
        user('logout')
        return()
    }

    if(is.null(public_key)){
        warning("Invalid key ID in token.")
        user('logout')
        return()
    }

    # get the decoded/validated information. 
    verified_token = jwt_decode_sig(input$idToken, pubkey = public_key)
    exp = as.POSIXct(verified_token$exp, origin = "1970-01-01", tz = "UTC")

    if(exp < Sys.time()){
        warning('Expired token.')
        user('logout')
        return()
    }

    user(list(email = verified_token$email))

})

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