Friendrank::Application.routes.draw do

  scope "/users", controller: :users do
    post "/create_and_or_sign_in", to: :create_and_or_sign_in
    get "/friends", to: :friends
    get "/friends_likes", to: :friends_likes
    get "/friends_likes_status", to: :friends_likes_status
    get "/top_friends", to: :top_friends
    get "/common_likes", to: :common_likes
  end

  root to: 'friends#index'
end
