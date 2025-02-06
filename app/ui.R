# app settings.
# best put here so shiny knows to reload when they change (changes to global.R won't trigger reloads).
app_title = 'R Shiny + Google Identity Platform'

ui = function(...){

  readRenviron('.Renviron')

  htmlTemplate(
    'templates/body.html', 
    app_title = app_title, 
    firebase_config = list(apiKey = Sys.getenv("PUBLIC_FIREBASE_API_KEY"), authDomain = Sys.getenv("PUBLIC_FIREBASE_AUTH_DOMAIN")),
    import_www = function(){

      ihead = list(
          # Google fonts. Left here just in case - but it's better if you add these locally to www/.
          # HTML('<link rel="preconnect" href="https://fonts.gstatic.com">'),
          # HTML('<link href="https://fonts.googleapis.com/css2?family=Raleway+Dots&family=Work+Sans:wght@300;400;500;700&family=Lato:wght@300;400;500;700&display=swap" rel="stylesheet">')
      )

      # add CSS and JS files from www/
      files.www =  gsub('www/', '', list.files( 'www', full.names = TRUE, recursive = TRUE))
      files.css = files.www[grepl('[.]css$', files.www, ignore.case = TRUE )]
      files.js = files.www[grepl('[.]js$', files.www, ignore.case = TRUE )]
      for(icss in files.css ) ihead[[length(ihead) + 1]] = HTML(paste0('<link rel="stylesheet" type="text/css" href="', icss, '">'))
      for(ijs in files.js) ihead[[length(ihead) + 1]] = HTML(paste0('<script src="', ijs, '"></script>'))
      
      return(ihead)
      
})}