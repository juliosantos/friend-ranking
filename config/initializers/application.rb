# Loading our library requires
require "#{Rails.root}/lib/external_resource"
require "#{Rails.root}/lib/facebook"

# Load heroku vars from local file
heroku_env = File.join(Rails.root, 'config', 'heroku_local_env.rb')
load(heroku_env) if File.exists?(heroku_env)

module App
  FB_APP_NAME  = ENV["FACEBOOK_APP_NAME"]
  FB_APP_ID    = ENV["FACEBOOK_APP_ID"]
  FB_SECRET    = ENV["FACEBOOK_APP_SECRET"]
  URL          = ENV["APP_URL"]
end
