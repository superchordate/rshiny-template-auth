# R Shiny Tailwind CSS Template

## About Me

I'm an independent contractor providing flexible end-to-end analytics support for startups and small teams. I offer low introductory rates, free consultation and estimates, and no minimums, so contact me today and let's chat about how I can help!

https://www.brycechamberlainllc.com

## Important Notes

* Anything in the `app/www/` folder will be publicly accessible, so take care!

## What is Tailwind?

Tailwind CSS is a utility-first framework that provides low-level utility classes to build designs directly in your HTML. 
Instead of writing CSS, you apply pre-built, atomic-ish classes directly to your elements. 

For example:

```html
<div class="flex items-center bg-blue-500 text-white p-4 rounded-lg shadow-md">
  <h2 class="text-xl font-bold">Hello World</h2>
</div>
```

This provides more flexibility than an opinionated framework like Bootstrap, at the cost of more complex and repetitive classing.

Tailwind CSS is mobile-first, making it intuitive and easy to design responsible applications. More info on this at https://tailwindcss.com/docs/responsive-design.

> Don't know Tailwind CSS? Claude and ChatGPT are very good at writing HTML with Tailwind CSS for any component, which you can then translate to an `htmlTemplate`.


## About this Project

This repo contains a working R Shiny app that uses Tailwind. You can use it to try Tailwind CSS out for yourself!

I'm hoping the code will be intuitive if you are familiar with R Shiny. If you aren't familiar, start at the [Tutorial](https://shiny.posit.co/r/getstarted/shiny-basics/lesson1/) instead. 

To use it, clone or download the files and run the app using RStudio:

![Screenshot of the R Shiny Template app.](https://github.com/superchordate/rshiny-template-tailwind/blob/main/img/screenshot.jpg)

The template is mobile-friendly:

![Screenshot of the R Shiny Template app on a mobile phone.](https://github.com/superchordate/rshiny-template-tailwind/blob/main/img/screenshot-mobile.jpg)

> The app is very simple, just a basic start. If you'd like to see a more mature app that uses this design, go to https://shinydemo.brycechamberlainllc.com.

![Screenshot of the R Shiny Template App](https://github.com/superchordate/rshiny-template-tailwind/blob/main/img/screenshot-shinydemo.jpg)


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