# Friend Ranking

## About

Friend Ranking is a basic demo app of some features of Facebook's Graph API. It will rank your friends according to how many Facebook likes you have in common with them.

## Context

I created this demo app to support my workshop at Social Media Week Berlin, «Fetching Open Graph Data — A Basic Introduction for Curious Developers». Please note that the app is not to be considered production-ready.

The app is ready for Heroku deployment, requiring 1 web dyno and 1 worker dyno. I use [foreman](https://github.com/ddollar/foreman) to run the background processes locally.

A live deployment is available at [friendrank.herokuapp.com](http://friendrank.herokuapp.com)

## Components not in version control

You will need a config/database.yml file, what with this being a Rails app and whatnot.

In order to run this locally, you will also need a config/heroku_local_env.rb file of the form:

    ENV["SENDGRID_PASSWORD"] = "..."
    ENV["SENDGRID_USERNAME"] = "..."
    ENV["APP_URL"]           = "..."
    ENV["FACEBOOK_APP_NAME"] = "..."
    ENV["FACEBOOK_APP_ID"]   = "..."
    ENV["FACEBOOK_SECRET"]   = "..."

Those same variables need to be added to the Heroku config for deployment:

    heroku config:add SENDGRID_PASSWORD=...
    heroku config:add SENDGRID_USERNAME=...
    heroku config:add FACEBOOK_APP_NAME=...
    heroku config:add FACEBOOK_APP_ID=...
    heroku config:add FACEBOOK_SECRET=...

Finally, it's important to note that the above assumes you created a Facebook app and connected it to your app.

# License

Copyright (c) 2012 Júlio Santos

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
