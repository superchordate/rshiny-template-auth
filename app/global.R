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
    allow_register_new_user = TRUE, # FALSE if you want to define your users on Identity Platform and not allow new users to register from the app.
    email_mfa_sms = TRUE, # require SMS MFA for email/password logins.
    google = TRUE, # log in with google account.
    invisible_recaptcha = TRUE # use invisible reCAPTCHA to prevent bots from registering new accounts. defaults to FALSE since extra setup is required. 
)

if(auth_methods$email_mfa_sms && !auth_methods$invisible_recaptcha) stop('[invisible_recaptcha] must be TRUE to use [email_mfa_sms]')

enableBookmarking(store = "url")
readRenviron('.env')

# check if the app is running locally. helpful for development. 
islocal = Sys.getenv('SHINY_PORT') == ""

# source any files in the app/global/ folder. 
for(i in list.files('global', pattern = '[.][Rr]', recursive = TRUE, full.names = TRUE)) source(i, local = TRUE)
rm(i)