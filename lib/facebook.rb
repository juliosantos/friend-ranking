module Facebook
  GRAPH_API_URL = 'https://graph.facebook.com/'

  class GenericException < StandardError; end
  class BadRequestException < StandardError; end

  def self.api_call(title, path, options={})
    options[:retry_timeout] ||= 20
    options[:limit] ||= 10000
    response = ExternalResource.load( title, options[:retry_timeout] ) do
      HTTPClient.get( GRAPH_API_URL + path, options )
    end

    raise GenericException if response.body == "false"

    return response.body if response.body.match( /^access_token=/ )

    json_response = JSON::parse( response.body )

    if response.status == 400
      raise BadRequestException.new( json_response["error"].values.join( ": " ) )
    end

    json_response
  end

  def self.batch_api_call( title, options = {} )
    options[:retry_timeout] ||= 20
    options[:limit] ||= 10000
    response = ExternalResource.load( title, options[:retry_timeout] ) do
      HTTPClient.post( GRAPH_API_URL, options )
    end

    json_response = JSON::parse( response.body )

    if response.status == 400
      raise BadRequestException.new( json_response["error"].values.join( ": " ) )
    end

    json_response
  end

  class Page
    def self.info(id)
      path = id.to_s
      Facebook.api_call( "#{self}.#{__method__}", path )

    end
  end

  class User
    def self.basic_info(options)
      request_options = { :access_token => options[:access_token] }
      path = user_path( options[:facebook_id] )
      Facebook.api_call( "#{self}.#{__method__}", path, request_options )
    end

    def self.friends(options)
      request_options = { :access_token => options[:access_token] }
      path = user_path( options[:facebook_id] )
      Facebook.api_call( "#{self}.#{__method__}", path + '/friends', request_options )
    end

    def self.likes(options)
      request_options = { :access_token => options[:access_token] }
      path = user_path( options[:facebook_id] )
      Facebook.api_call( "#{self}.#{__method__}", path + '/likes', request_options )
    end

    private

    def self.user_path( facebook_id = nil )
      user_path = ( facebook_id.present? ) ? facebook_id.to_s : 'me'
    end
  end
end
