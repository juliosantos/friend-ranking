class UsersController < ApplicationController
  def create_and_or_sign_in
    user = User.create_or_update_from_access_token( params[:access_token] )

    render :nothing => true
  end

  def friends
    user = User.find_by_access_token( params[:access_token] )

    # do this only once; updating friends should be an overnight job, anyway
    user.fetch_fb_friends unless user.friends_fetched?

    friends = user.friends.map do |friend|
      {
        :facebook_uid => friend.facebook_uid,
        :name => friend.name
      }
    end

    render :json => friends
  end

  def friends_likes
    user = User.find_by_access_token( params[:access_token] )
    user.update_attribute( :email, params[:email] ) unless params[:email].blank?
    user.update_attribute( :unicorns, params[:unicorns] == "true" ? true : false )

    if user.friends_likes_fetched?
      UsersMailer.friends_likes_email( user ).deliver unless params[:email].blank?
      render :json => user.friends_likes_count
    elsif user.friends_likes_fetching?
      render :text => "pending"
    else
      user.update_attribute( :friends_likes_fetching, true )
      user.delay.fetch_friends_likes_graph_api
      render :text => "pending"
    end
  end

  def friends_likes_status
    user = User.find_by_access_token( params[:access_token] )

    if user.friends_likes_fetching?
      render :text => "pending"
    else
      render :text => "complete"
    end
  end

  def top_friends
    user = User.find_by_access_token( params[:access_token] )

    top_ranking_friends = user.top_ranking_friends

    pruned_ranking = top_ranking_friends.map do |top_ranking_friend|
      {
        :facebook_uid => top_ranking_friend[:user].facebook_uid,
        :name => top_ranking_friend[:user].name,
        :n_common_likes => top_ranking_friend[:n_common_likes]
      }
    end

    render :json => pruned_ranking
  end

  def common_likes
    user = User.find_by_access_token( params[:access_token] )
    friend = User.find_by_facebook_uid( params[:friend_facebook_uid] )

    common_likes = user.common_likes_with( friend ).map( &:likee ).map do |likee|
      {
        :title => likee.name,
        :fb_id => likee.fb_id
      }
    end

    render :json => user.common_likes_with( friend ).map( &:likee ).map 
  end
end
