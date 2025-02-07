require(shiny)
require(magrittr) # for %<>%
require(openssl) # for verifying tokens.
require(jose)
require(jsonlite)

# app settings. 
app_title = 'R Shiny + Auth'
auth_methods = list(email = FALSE, google = TRUE)

enableBookmarking(store = "url")
readRenviron('.env')

# check if the app is running locally. helpful for development. 
islocal = Sys.getenv('SHINY_PORT') == ""

# source any files in the app/global/ folder. 
for(i in list.files('global', pattern = '[.][Rr]', recursive = TRUE, full.names = TRUE)) source(i, local = TRUE)
rm(i)

