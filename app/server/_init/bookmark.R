# this file is used to manage bookmarking in the app.

# clean up the bookmark URL by excluding values we don't need to save. 
exclude_from_bookmark = c('sidebarCollapsed', 'sidebar_reset', 'idToken', 'recaptcha_token')

# observer to update the bookmark URL when inputs change.
observe({
    # reference bookmarked inputs here to trigger bookmark updates when they change. 
    # reactiveto = c(input$myinput1, input$myinput2)
    setBookmarkExclude(exclude_from_bookmark)
    session$doBookmark()
})

# URL cleanup.
onBookmarked(function(url) {
    updateQueryString(gsub('&[^=]+=null', '', url))
})

# add any special tasks to perform when restoring a bookmark.
onRestore(function(state) {
    bookmarked_inputs = unlist(state$input)
})