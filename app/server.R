server = function(input, output, session) {
  
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
      user(NULL)
      return()
    }

    if(is.null(public_key)){
      warning("Invalid key ID in token.")
      user(NULL)
      return()
    }
    
    # get the decoded/validated information. 
    verified_token = jwt_decode_sig(input$idToken, pubkey = public_key)
    exp = as.POSIXct(verified_token$exp, origin = "1970-01-01", tz = "UTC")

    if(exp < Sys.time()){
      warning('Expired token.')
      user(NULL)
      return()
    }
    
    user(list(email = verified_token$email))
    
  })

  # the _init folder is set up to run first. useful when there are dependent files downstream.
  # source any files in app/server/_init/.
  initfiles = list.files('server/_init/', pattern = '[.][Rr]$', full.names = TRUE)
  for(i in initfiles) source(i, local = TRUE)
  rm(i)

  # then run the rest of the app/server/ files. 
  dofiles = list.files('server', pattern = '[.][Rr]$', recursive = TRUE, full.names = TRUE)
  dofiles = dofiles[!grepl('_init', dofiles)]
  for(i in dofiles) source(i, local = TRUE)
  rm(i)
  
  # show login when logout condition applies.
  output$login = renderUI({ if(!is.null(user()) && user() == 'logout') { htmlTemplate("templates/login.html", auth_methods = auth_methods) } })

  # this output hides all app content behind the authorization flow.
  output$protected = renderUI({
    if(!is.null(user()) && is.list(user()) && !is.null(user()$email)){ 
      htmlTemplate("templates/protected.html") 
  }})
}
