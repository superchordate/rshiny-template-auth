require(shiny)
require(magrittr) # for %<>%
require(openssl) # for verifying tokens.
require(jose)
require(jsonlite)

# app settings. 
# ! these only control the UI. make sure to set these same auth settings in Identity Provider to ensure users can't do anything you don't want them to.
app_title = 'R Shiny + Auth'
auth_methods = list(email = TRUE, google = TRUE, allow_register_new_user = TRUE)

enableBookmarking(store = "url")
readRenviron('.env')

# check if the app is running locally. helpful for development. 
islocal = Sys.getenv('SHINY_PORT') == ""

# source any files in the app/global/ folder. 
for(i in list.files('global', pattern = '[.][Rr]', recursive = TRUE, full.names = TRUE)) source(i, local = TRUE)
rm(i)

