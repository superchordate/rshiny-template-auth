# R Shiny + Auth Template

## About Me

I'm an independent contractor providing flexible end-to-end analytics support for startups and small teams. I offer low introductory rates, free consultation and estimates, and no minimums, so contact me today and let's chat about how I can help!

https://www.techbybryce.com


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

![Screenshot of the app](https://github.com/superchordate/rshiny-template-auth/blob/main/img/screen.jpg)

## Identity Platform Setup

Settings must be manually lined up in Identity Platform as well as global.R which controls the UI and some limited server-side checks.

*During these steps, you might see a pop-up that says "Cloud Functions API has not been used in project testauth-451418 before or it is disabled." You can ignore this and click "CLOSE".

* Initialize Project on Google Cloud Platform (GCP): Create a new project to make it easier to delete all the resources when you are finished testing.
  - Follow the steps at https://developers.google.com/workspace/guides/create-project including setting up a billing account. Don't worry, you won't get charged until you hit 50,000 monthly active users<sup>[1](https://cloud.google.com/identity-platform/pricing)</sup>. You can set up [billing alerts](https://cloud.google.com/billing/docs/how-to/budgets) to be more sure you won't see high billing. 
  - Go to https://console.cloud.google.com/customer-identity/providers and click "Enable Identity Platform."

* Disable new user registration (optional):
  - If you can manage users yourself by adding them in Identity Platform, that is more secure than allowing new registration via the site. This template will use reCAPTCHA to try and reduce registrations by bots, but it is not difficult for bots to get around this restriction. 
  - Click Settings (expand the left sidebar) > Un-check "Enable create (sign-up)", Un-check "Enable delete" > Click SAVE. If you don't do this, new users can register through Log In with Google even if you have allow_register_new_user = FALSE in global.R.
  - This will ensure users can only be modified by you, using the GCP console.

If you would like to allow users to log in with email (recommended): 

  * Go to https://console.cloud.google.com/customer-identity/providers and click "ADD A PROVIDER."
  * Select "Email / Password" and click "Enabled" and "Save."

If you would like to use the "Login with Google" feature, follow the steps below. It's complicated, but I'd recommend attempting it since it's a nice option for users. Otherwise, skip to the next section.

* Create Oauth App: The steps from Google on this aren't super clear, so use these:
  - Go to https://console.cloud.google.com/apis/credentials. Notice how the "OAuth 2.0 Client IDs" section is empty. We need to add one.
  - Click "Create Credentials" and select "OAuth Client ID"
  - Click "Configure Consent Screen" on the right. 
  - This will take you to the "Create branding" page. Click "Get Started"
  - Choose an app name ("test" is OK for now) and set your email as the "User support email". Click "NEXT".
  - Select "External" and click "NEXT".
  - Enter your email and click "NEXT".
  - Review the linked Google API Services User Data Policy, check the box if you agree to be bound by it, and click "CONTINUE".
  - Click "CREATE".
  - Later, come back to https://console.cloud.google.com/auth/branding and add your home page, privacy policy link, and terms of service link.

* Create OAuth Client:
  - Go to https://console.cloud.google.com/auth/overview.
  - Click "CREATE OAUTH CLIENT" at the right. 
  - If you see don't see the "Create OAuth client ID" screen, click "Configure Consent Screen" on the right. 
  - Select "Application Type" = "Web application".
  - Use the default "Name" or choose one ("test" is fine).
  - We'll come back to fill this in later. For now, click "CREATE".

* Add OAuth Test User:
  - Go to https://console.cloud.google.com/auth/audience.
  - Under "Test users", click "+ ADD USERS".
  - Add your email address, and the email of anyone else that needs access during testing.
  - Click "SAVE".

* Set up Google Login:
  - Go to https://console.cloud.google.com/customer-identity/providers and click "Add Provider" and select Google. 
  - In a different window, open https://console.cloud.google.com/apis/credentials and click your OAuth 20 Client ID.
  - Copy and paste the Client ID and Client Secret into the Google Add Provider page.
  - Click "SAVE".

Create .env file:

* Create an empty file in the `app/` folder called `.env` and copy in the text below:

```
PUBLIC_FIREBASE_API_KEY=paste_key_here
PUBLIC_FIREBASE_AUTH_DOMAIN=paste_domain_here
```

* Copy your Firebase info into the project. 
  - Go to https://console.cloud.google.com/customer-identity/providers and click "APPLICATION SETUP DETAILS" on the right. 
  - Copy the `apiKey` and `authDomain` to replace `paste_key_here` and `paste_domain_here`, respectively. Don't include any `'` or `"`.

* Even though these are public keys, the .env file will be ignored by Git so your keys don't get pushed to GitHub. See more about key security below under heading "On the Web".

MFA: Ultimately, passwords aren't enough to protect sensitive data<sup>[4](https://techcommunity.microsoft.com/blog/microsoft-entra-blog/your-paword-doesnt-matter/731984)</sup>. It is smart to also require MFA on your accounts. If you would like to use two-factor authentication (2FA/MFA) with SMS/text

* Go to https://console.cloud.google.com/customer-identity/mfa.
* Click "Enable" 
* Note the options here. You can customize your SMS here.
* When you are ready, click "Save". Or, just click it to accept defaults. You can come back to change it later.
* Go to https://console.cloud.google.com/customer-identity/providers and switch Phone to Enabled.

You also need to enable the region. 

* Go to https://console.firebase.google.com/u/0/
* Select your project
* On the left menu, click "Build" and then "Authentication".
* On the tab menu,click "Settings"
* Click "SMS region policy" and "Select regions". Select "United States (US)" and "Save".

<!-- These steps pending removal during testing of using the Firebase API key instead of creating separate reCAPTCHA keys.

If you would like to set up reCAPTCHA to prevent some bot activity, follow the steps below. Google requires reCAPTCHA checks before any SMS send, so you must follow these steps if you want to use MFA.

* reCAPTCHA verification is free for up to 10,000 assessments per organization, and super cheap after that.<sup>[2](https://cloud.google.com/security/products/recaptcha?pricing&hl=en#pricing)</sup> You can be alerted if the reCAPTCHA starts getting hit excessively. See [this forum post](https://stackoverflow.com/questions/78450805/monitoring-and-alerts-configuration-for-google-recaptcha-v3-enterprise-edition).

* This template uses invisible reCAPTCHA, which mostly runs in the background but will pop up asking the user to click images if there is any unusual activity.

* Enable reCAPTCHA: 
  - Go to https://console.cloud.google.com/security/recaptcha and click "ENABLE".
  - Click "+ Create Key"
  - Choose a "Display name". "test" is fine for now.
  - Choose "platform type" = "Website".
  - Click "Add a domain" and enter your R Shiny domain (see "How to Find My R Shiny Dev Domain" below).

  - Click "Create key".
  - Note your ID now at the top of the screen. Copy it and add the it to `.env` as `PUBLIC_RECAPTCHA_SITE_KEY`.

* Create a Google API Key for the server to access your project's reCAPTCHA. 
  - Go to https://console.cloud.google.com/apis/credentials
  - Click Create Credentials, select API Key, click ... to the right of you new key, select Edit API Key
  - Set Name = "recaptcha", Restrict Key = reCAPTCHA Enterprise API
  - Click Show key, copy into `.env` as `RECAPTCHA_API_KEY`
  - Click Close and Save
  - To further secure it, only allow usage from your website: Under "Application restrictions" select "Website", click "+ ADD" and enter your full website "https://www.yoursite.com".

* This may require extra setup when publishing to the web. The server must be authenticated with reCAPTCHA and your google project. I expect this will be automatic if using Google Cloud Run on the same project, but it might be tricky on other publishing platforms. See https://cloud.google.com/recaptcha/docs/authentication for more information.  

-->

Authorize the local R Shiny development domain, or your web domain if publishing to the web.

  * Go to https://console.cloud.google.com/customer-identity/settings.
  * Click "SECURITY". 
  * Click 'ADD DOMAIN" and enter your R Shiny domain (see "How to Find My R Shiny Domain" below).

If you are using Log in With Google, authorize the Oauth client for your Firebase app:

  * Go to https://console.cloud.google.com/apis/credentials and select your OAuth 2.0 Client ID. 
  * Get your `authDomain`: In another tab, go to https://console.cloud.google.com/customer-identity/providers and click "APPLICATION SETUP DETAILS" on the right. 
  * Go back to the Ouath tab. Under "Authorized redirect URIs", click "+ ADD URI".
  * Enter your the auth handler URL for your `authDomain`. Take `https://{authDomain}/__/auth/handler` and replace "authDomain" with your `authDomain`. For example, if my `authDomain` is "testauth-451418.firebaseapp.com" then I'll enter the URI "https://testauth-451418.firebaseapp.com/__/auth/handler".

If you are not using Email / Password Login, Log In with Google, New User Registration, or MFA set the appropriate values to `FALSE` at `app/global.R` lines 12-17. 

You are done setting up Identity Platform! Celebrate with a latte. :coffee:

Then, continue by running the app in RStudio. You can now perform all the login operations! (assuming you are one of the authorized Test Users, if using Log In with Google)


## How to Find My R Shiny Domain

This section assumes you are running R Shiny locally.

* Run the app using RStudio or your preferred method.
* Note the URL. For me it is "http://127.0.0.1:4201/?".
* The domain is the part in the middle, in this case "127.0.0.1"
* If on the web, your domain might be something like "https://shinydemo.brycechamberlainllc.com" in which case the domain is "shinydemo.brycechamberlainllc.com".


## On the Web

_Disclaimer: I can't make any guarantees that the authorization here is 100% secure. We all must be responsible for our own security, so be sure to study up and review this code, or consult an expert, if you decide to use this template in production._

When you move this to the web, you'll need to replace your dev domain with your prod domain. It is **CRITICAL** to remove the dev domain from anywhere you added it. Otherwise, someone else could use your public Firebase keys to run Firebase operations from their local development environments. They wouldn't be able to do anything you have disallowed in Identity Provider settings, but this would be a major security risk either way. If you would like a dev environment, use a different GCP project and keep your Firebase API keys very secret! 

Here are the places where it might need to be replaced. 

* https://console.cloud.google.com/customer-identity/providers > Settings > Security > Authorized Domains
* https://console.cloud.google.com/apis/credentials > OAuth 2.0 Client ID > Authorized JavaScript origins, Authorized redirect URIs.
* https://console.cloud.google.com/security/recaptcha > Key details > Edit key > Domain list.

**Or, even better, start a new project and use your public domain instead of your dev domain.** That way you can be sure the project doesn't have the local domain anywhere.

I'm hoping this will work on just about any platform, since it runs entirely in R on the server and JS on the front-end. Both will be available on any platform that can run an R Shiny app. 

On the web, you'll be gathering sensitive data like email and phone numbers for MFA. You should have a Privacy Policy and Terms of Service set up. You can add this information to your Google Cloud project at https://console.cloud.google.com/auth/branding.

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