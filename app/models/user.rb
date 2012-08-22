class User < ActiveRecord::Base
  has_many :likes
  has_many :fb_likes, through: :likes, source: :likee, source_type: "FbLike"
  #has_many :lastfm_likes, through: :likes, source: :likee, source_type: "LastFmLike"

  has_many :friendships
  has_many :friends, through: :friendships

  def self.basic_info (access_token)
    Facebook::User.basic_info( :access_token => access_token )
  end

  def self.create_or_update_from_access_token (access_token)
    fb_user = self.basic_info( access_token )

    # do we already have this user?
    user = User.find_by_facebook_uid( fb_user["id"] )

    if user.present?
      user.update_attribute( :access_token, access_token )
      user.delay.update_basic_info( fb_user )
    else
      # create user with very basic stuff
      user = User.new
      user.facebook_uid = fb_user["id"]
      user.access_token = access_token
      user.save

      # update user with basic FB info
      user.update_basic_info( fb_user )
    end

    user.delay.fetch_fb_likes unless user.likes_fetched?

    return user
  end

  def update_basic_info (fb_user=nil)
    fb_user ||= self.basic_info

    # update basic info
    User.transaction do
      self.name           = fb_user["name"]
      self.email          = fb_user["email"]
      self.first_name     = fb_user["first_name"]

      self.save
    end
  end

  def fetch_fb_likes
    likes = Facebook::User.likes( access_token: self.access_token, facebook_id: self.facebook_uid )
    self.create_likes_from_fb_response( likes["data"] )

    self.update_attribute( :likes_fetched, true )
  end

  def fetch_fb_friends
    friends = Facebook::User.friends( access_token: self.access_token )["data"]

    existing_users = User.pluck( :facebook_uid )
    new_users = friends.reject{ |friend| existing_users.include? friend["id"] }

    if new_users.any?
      values_for_users = new_users.map{ |friend| "('#{friend["id"]}', '#{PG::Connection.escape_string( friend["name"] )}')" }
      users_insert_query = "INSERT INTO users (facebook_uid, name) VALUES #{values_for_users.join( "," )}"
      ActiveRecord::Base.connection.execute( users_insert_query )
    end

    if friends.any?
      # All friends must be deleted first; inserting only the new ones will cause
      # unfriending not to have any effect.
      # Delete all user's friendships:
      friendships_delete_query = "DELETE FROM friendships WHERE user_id = #{self.id}"
      ActiveRecord::Base.connection.execute( friendships_delete_query )

      friendships_insert_query = "INSERT INTO friendships (user_id, friend_id) SELECT #{self.id}, id FROM users WHERE facebook_uid IN (#{friends.map{ |friend| "'#{friend["id"]}'" }.join(",")})"
      ActiveRecord::Base.connection.execute( friendships_insert_query )
    end

    self.update_attribute( :friends_fetched, true )
  end

  def create_likes_from_fb_response (likes)
    existing_likes = FbLike.pluck( :fb_id )
    new_likes = likes.reject{ |like| existing_likes.include? like["id"] }

    values_for_fb_likes_insert = []
    new_likes.each do |like|
      values_for_fb_likes_insert << "('#{like["id"]}', '#{PG::Connection.escape_string( like["name"] )}', '#{PG::Connection.escape_string( like["category"] )}')"
    end

    if new_likes.any?
      # mass insert into fb_likes
      fb_likes_insert_query = "INSERT INTO fb_likes (fb_id,name,category) VALUES #{values_for_fb_likes_insert.join( "," )}"
      ActiveRecord::Base.connection.insert( fb_likes_insert_query )
    end

    if likes.any?
      # All likes must be deleted first; inserting only the new ones will cause
      # unlikes not to have any effect. Also, they will be duplicated in case
      # this user is someone else's friend.
      # Delete all user's likes:
      likes_delete_query = "DELETE FROM likes WHERE user_id = #{self.id}"
      ActiveRecord::Base.connection.execute( likes_delete_query )

      # mass insert into user's likes
      likes_insert_query = "INSERT INTO likes (user_id, likee_id, likee_type) SELECT #{self.id}, fb_likes.id, 'FbLike' FROM fb_likes WHERE fb_id IN (#{likes.map { |like| "'#{like["id"]}'" }.join( "," ) })"
      ActiveRecord::Base.connection.insert( likes_insert_query )
    end

    GC.start
  end

  def fetch_friends_likes_graph_api
    batches = []
    self.friends.order( :id ).each do |friend|
      batches << { :relative_url => "#{friend.facebook_uid}/likes", :method => "GET" }
    end

    fb_responses = []
    threads = []
    batches.in_groups_of( 50, false ).each do |batch|
      threads << Thread.new do
        batch_response = Facebook::batch_api_call( "friends' likes", {
          :access_token => self.access_token,
          :batch => batch.to_json
        })
        Thread.current["fb_response"] = batch_response.map do |response|
          next if response.nil?
          JSON::parse( response["body"] )["data"]
        end
        nil
      end
    end
    
    threads.each do |thread|
      thread.join
      fb_responses += thread["fb_response"]
      thread["fb_response"] = nil
    end

    threads.clear

    existing_fb_likes = FbLike.pluck( :fb_id )

    # merge these lines for GC
    new_fb_likes = fb_responses.flatten.compact.reject{ |like| existing_fb_likes.include?( like["id"] ) }
    values_for_fb_likes_insert = new_fb_likes.map { |like| [like["id"],like["name"],like["category"]] }.uniq.map do |like|
      "('#{like[0]}', '#{PG::Connection.escape_string( like[1] )}', '#{PG::Connection.escape_string( like[2] )}')"
    end

    values_for_likes_insert = self.friends.order(:id).zip(fb_responses).select{ |friend,likes| likes && likes.any? }.map { |friend, likes| likes.map { |like| "(#{friend.id}, '#{like["id"]}')" }  }

    ActiveRecord::Base.transaction do
      if new_fb_likes.any?
        fb_likes_insert_query = "INSERT INTO fb_likes (fb_id,name,category) VALUES #{values_for_fb_likes_insert.join( "," )}"
        ActiveRecord::Base.connection.execute( fb_likes_insert_query )

        # All likes must be deleted first; inserting only the new ones will cause
        # unlikes not to have any effect.
        # Delete all friends' likes:
        likes_delete_query = "DELETE FROM likes WHERE user_id IN (SELECT friend_id FROM friendships WHERE user_id = #{self.id})"
        ActiveRecord::Base.connection.execute( likes_delete_query )

        likes_insert_query = "INSERT INTO likes (user_id, likee_id, likee_type) SELECT x.user_id, fb_likes.id, 'FbLike' FROM (VALUES #{values_for_likes_insert.flatten.join( "," )}) x(user_id, fb_id) JOIN fb_likes ON x.fb_id = fb_likes.fb_id"
        ActiveRecord::Base.connection.execute( likes_insert_query )
      end
    end

    UsersMailer.friends_likes_email( self ).deliver if self.email.present?
    self.update_attribute( :friends_likes_fetched, true )
    self.update_attribute( :friends_likes_fetching, false )

    ActiveRecord::Base.connection_pool.clear_stale_cached_connections!
    GC.start
  end

  # TODO update method to match new spec
  def fetch_friends_likes_fql (accurate=false)
    page_likes = []
    if accurate == false
      # Facebook trades accuracy for performance; this query won't return all results
      query = "SELECT uid, page_id FROM page_fan WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me())"
      page_likes = Facebook::api_call( "friends' page likes FQL", "fql", { :q => query, :access_token => self.access_token, :retry_timeout => 30 } )["data"]
    else
      # less friends at a time keeps Facebook happy and they'll confortably fit more likes in a single response;
      # all these queries take way longer, though, not to mention the inserts below
      threads = []
      self.friends.pluck( :facebook_uid ).in_groups_of( 25 ).map( &:compact ).each do |uid_group|
        threads << Thread.new do
          query = "SELECT uid, page_id FROM page_fan WHERE uid IN (#{uid_group.join(",")})"
          Thread.current["page_likes"] = Facebook::api_call( "friends' page likes FQL", "fql", { :q => query, :access_token => self.access_token, :retry_timeout => 30 } )["data"]
        end
      end

      threads.each do |thread|
        thread.join
        page_likes += thread["page_likes"]
      end
    end

    page_likes.group_by{ |page_like| page_like["uid"] }.each do |facebook_uid, page_likes|
      user = User.find_by_facebook_uid( facebook_uid.to_s )
      page_likes.each do |page_like|
        #user.fb_likes << FbLike.find_or_initialize_by_fb_id( page_like["page_id"].to_s )
        # raw sql is much master here
        likee_id = ActiveRecord::Base.connection.select_value( "SELECT id FROM fb_likes WHERE fb_id = '#{page_like["page_id"]}'" ) || ActiveRecord::Base.connection.insert( "INSERT INTO fb_likes (fb_id) VALUES (#{page_like["page_id"]})" )
        ActiveRecord::Base.connection.insert( "INSERT INTO likes (user_id,likee_id) VALUES (#{user.id}, #{likee_id})" )
      end
    end
  end

  def friends_likes_count
    sql_query = "SELECT users.facebook_uid, COUNT (*)
        FROM likes join users ON likes.user_id = users.id
        WHERE user_id IN (SELECT friend_id FROM friendships WHERE user_id = #{self.id})
        GROUP BY users.id"

    results = ActiveRecord::Base.connection.execute( sql_query )

    results.map do |friend|
      {
        :facebook_uid => friend["facebook_uid"],
        :likes_count => friend["count"]
      }
    end
  end

  def top_ranking_friends (limit=10)
    sql_query = "SELECT a.user_id, COUNT(1)
        FROM likes a JOIN likes b ON a.likee_id = b.likee_id
        WHERE b.user_id = #{self.id} AND a.user_id <> #{self.id} AND a.user_id IN (SELECT friend_id FROM friendships WHERE user_id = #{self.id})
        GROUP BY a.user_id
        ORDER BY COUNT DESC
        LIMIT #{limit}"
    result = ActiveRecord::Base.connection.select_rows( sql_query )

    result.map{ |r| { :user => User.find( r[0] ), :n_common_likes => r[1] } }
  end

  def common_likes_with (user)
    user.likes.where( :likee_id => self.likes.pluck( :likee_id ) )
  end
end
