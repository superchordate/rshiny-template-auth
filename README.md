# R Shiny + Auth Template

## About Me

I'm an independent contractor providing flexible end-to-end analytics support for startups and small teams. I offer low introductory rates, free consultation and estimates, and no minimums, so contact me today and let's chat about how I can help!

https://www.brycechamberlainllc.com


## About This Project

_Disclaimer: I can't make any guarantees that the authorization here is 100% secure. We all must be responsible for our own security, so be sure to study up and review this code, or consult an expert, if you decide to use this template in production._

In my search for authorization solutions, I've been very happy with Google's [Identity Platform](https://cloud.google.com/security/products/identity-platform?hl=en). It uses the authentication from Firebase while not requiring a full Firebase project with storage, data, etc. 
* You can use it regardless of where you decide to host your final project.
* You can connect multiple apps to the same provider so your users don't need a new password for each site. 
* It is free for up to 49,999 monthly active users<sup>[1](https://cloud.google.com/identity-platform/pricing)</sup>.

Here is how this project handles authentication and authorization:

* The top-level template `app/templates/body.html` acts as the gatekeeper for protected content. It exposes two outputs: `login` (the login form) and `protected` (the server will send protected content here but only after verifying authorization).
* `app/templates/protected.html` is where the app's main body lives. It will only be shown after authorization.
* Authentication is handled by [Identity Platform](https://cloud.google.com/security/products/identity-platform?hl=en) which requires some setup. Instructions are below. 
* Code in `app/templates/body.html` initializes the firebase app object (including auth) and listens for changes in authorization state. If the app becomes authorized, it sends the idToken to the server for validation.
* Code in `app/templates/login.html` handles necessary user input and authorization flows for registration, password reset, and log out. 
* `app/server.R` receives the idToken from the client, verifies it using Google's public certificate, and sends protected content after verification. Server-side verification is critical because anyone can send a user to the server with `Shiny.setInputValue`.

This project is built on top of my [Tailwind CSS template](https://github.com/superchordate/rshiny-template-tailwind). I'm hoping the code will be intuitive if you are familiar with R Shiny. If you aren't familiar, start at the [Tutorial](https://shiny.posit.co/r/getstarted/shiny-basics/lesson1/) instead. 

To use this project:

* Download or clone the project.
* Set up Identity Platform (see below).
* Run the app in RStudio.


## Identity Platform Setup

* Initialize Project on Google Cloud Platform: Create a new project to make it easier to delete all the resources when you are finished testing.
  - Follow the steps at https://developers.google.com/workspace/guides/create-project including setting up a billing account. Don't worry, you won't get charged until you hit 50,000 monthly active users^[1](https://cloud.google.com/identity-platform/pricing). You can set up [billing alerts](https://cloud.google.com/billing/docs/how-to/budgets) to be more sure you won't see high billing. 
  - Go to https://console.cloud.google.com/customer-identity/providers and click "Enable Identity Providers."

* If you would like to allow users to log in with email (recommended): 
  - Go to https://console.cloud.google.com/customer-identity/providers and click "ADD A PROVIDER."
  - Select "Email / Password" and click "Enabled" and "Save."

If you would like to use the "Login with Google" feature, follow the steps below. It's complicated, but I'd recommend attempting it since it's a nice option for users. Otherwise, skip to the next section.

* Create Oauth Consent Screen: The steps from Google on this aren't super clear, so use these:
  - Go to https://console.cloud.google.com/apis/credentials. Notice how the "OAuth 2.0 Client IDs" section is empty. We need to add one.
  - Click "Create Credentials" and select "OAuth Client ID"
  - Click "Configure Consent Screen" on the right.
  - Select User Type = "External" and "Create".
  - Oauth Consent Screen: Fill in the required fields as best you can. In production, you'll want to carefully go through this. For now, the values aren't that important. Save and Continue.
  - Scopes: Leave blank for now. Save and Continue.
  - Test users: Add yourself as a test user.

* Create Oauth Client: Now we can create the actual client.
  - Go to https://console.cloud.google.com/apis/credentials. Notice how the "OAuth 2.0 Client IDs" section is empty. We need to add one.
  - Click "Create Credentials" and select "OAuth Client ID"
  - Select Application Type = "Web application" and enter a name.
  - Click "Create". The "OAuth client created" will pop up. Copy the Client ID and Client Secret to Notepad, you'll need both shortly. You can access them later by selecting your Oauth client at https://console.cloud.google.com/apis/credentials.

* Set up Google Login.
  - Go to https://console.cloud.google.com/customer-identity/providers and click "Add Provider" and select Google. 
  - Paste in your Client ID and Client Secret and click Save. 

Now we'll set up the R Shiny app. 

* Create your `.env` file. It will hold the keys your app needs.
  - Create an empty file in the `app/` folder called `.env` and copy in the text below:

```
PUBLIC_FIREBASE_API_KEY=paste_key_here
PUBLIC_FIREBASE_AUTH_DOMAIN=paste_domain_here
```

* Copy your Firebase info into the project. 
  - Go to https://console.cloud.google.com/customer-identity/providers and click "APPLICATION SETUP DETAILS" on the right. 
  - Copy the `apiKey` and `authDomain` to replace `paste_key_here` and `paste_domain_here`, respectively. Don't include any `'` or `"`.

* Authorize the local R Shiny development domain. 
  - Run the app and note the URL. For me it is "http://127.0.0.1:4201/?".
  - Go to https://console.cloud.google.com/customer-identity/providers and click Settings (expand the left sidebar).
  - Click "Security". We need to authorize the domain part of this: 127.0.0.1.
  - Click 'ADD DOMAIN", enter "127.0.0.1" (or the value you see) and "SAVE."
  - If you are using Sign In with Google: We also need to add it to the Oauth client's Authorized redirect URIs. Go to https://console.cloud.google.com/apis/credentials and select your Oauth client. 
  - Under "Authorized redirect URIs", click "+ ADD URI."
  - Enter "http://127.0.0.1" (or the value you see) and click "SAVE".

If you aren't using email, or aren't using Log In with Google, set the appropriate value to `FALSE` at `app/server.R` line 4. 

You are done setting up Identity Platform! Celebrate with a latte. :coffee:

Then, continue by running the app in RStudio. 


## Design Notes

**Not a Package**

This project uses JS files directly, as opposed to packaging them into an R package. This gives developers the flexibility to use whichever version of Tailwind they like. 

The Tailwind JS file is saved at `app/www/tailwind_3_4_3.js`. You can replace it with any Tailwind version you like. Any CSS or JS files in `app/www/` are automatically imported by `app/ui.R` and `uihead()`.

I've also downloaded Fonts and saved them to `app/www/fonts/` and set up with `app/www/fonts/fonts.css`. Refer to `fonts.css` for info on how to add new fonts. 

_To find JS files and CSS files that can be used in this way, find a CDN that provides them, visit the URL, and save the file to the app/www folder._


**app Folder**

I place all the files in an `app/` folder because I usually have data scripts that I want to keep in the same project. 


**Easy File Swapping** 

This template uses a system I've set up to make complex R Shiny projects easier to manage. 

* `global.R`, `server.R`, and `ui.R` each have functions that will automatically read in files saved in folders within `app/` with the same name (`app/global/`, `app/server/`, `app/ui/`).
* `ui.R` only handles high-level elements, while most of the UI is built using server files saved in the `app/server/` folder. 
* I use Visual Studio Code to navigate the files and folder structure. In my experience, VS Code is better than RStudio for working with complex projects. `Ctrl+P` is a lifesaver! I still use RStudio to run code and debug with `browser()`, though. 

**hcslim**

This project uses [hcslim](https://github.com/superchordate/hcslim/) to utilize Highcharts for plotting. 

* Charting defaults are set at `app/www/highcharts-defaults.js`.
* Highcharts .js files are at `app/www/highcharts`. You can add/remove modules here. 
* hcslim functions are at `app/server/_init/hcslim.R`

**HTML Templates**

When breaking free of opinionated frameworks, it is much easier to write UI in HTML. This project uses HTML templates, saved in the `app/templates/` folder. More on this at https://shiny.posit.co/r/articles/build/templates/.

**Personal Style**

You'll notice I don't follow normal R conventions like using `<-` or modules, and seemingly random selection of `'` and `"` as a result of mixing AI results with my personal preference for `'` because it doesn't require the shift key. 

Please bear with me on this and feel free to search and replace your own style. :relieved:

Or, clean up my code in a PR. Though I can't guarantee I'll accept it. :pray: