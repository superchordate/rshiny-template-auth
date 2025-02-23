require(shiny)
require(magrittr) # for %<>%
require(openssl) # for verifying tokens.
require(jose)
require(jsonlite)
require(httr)

# app settings. 
# ! these only control the UI. make sure to set these same auth settings in Identity Provider to ensure users can't do anything you don't want them to.
# see the README for setup instructions.
app_title = 'R Shiny + Auth'
auth_methods = list(    
    email = TRUE, # email and password registration, login, forgot password.
    allow_register_new_user = TRUE, # allow new users to register. 
    google = TRUE, # log in with google account.
    invisible_recaptcha = TRUE, # use invisible recaptcha to prevent some bot activity.
    mfa_sms = TRUE # require two-factor authentication by SMS.
)

if(auth_methods$mfa_sms && !auth_methods$invisible_recaptcha) stop('MFA requires invisible recaptcha. Please enable it in the auth_methods list.')

# check if the app is running locally. helpful for development. 
islocal = Sys.getenv('SHINY_PORT') == ""

enableBookmarking(store = "url")
readRenviron(ifelse(islocal, '../.env-dev', '.env'))

# source any files in the app/global/ folder. 
for(i in list.files('global', pattern = '[.][Rr]', recursive = TRUE, full.names = TRUE)) source(i, local = TRUE)
rm(i)