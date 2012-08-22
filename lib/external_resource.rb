module ExternalResource
  # Requires a block with the HTTPClient.get call or what-have-you
  def self.load(name="", seconds=20)
    retries = 12
    total   = retries

    Rails.logger.info( "Started ExternalResource load call to: #{name}" )

    begin
      r = Timeout.timeout( seconds ) do
        yield
      end
      return r
    rescue Timeout::Error
      puts "Timeout!"
      Rails.logger.error( "Hit elusive 'Time's up!' error" )

      retries -= 1
      sleep 0.5 and retry
    rescue => e
      retries -= 1

      Rails.logger.info( "Working on retry ##{retries} of #{total}" )
      Rails.logger.error( e )

      if retries > 0
        sleep 0.5 and retry
      else
        Rails.logger.error( "ERROR: Unable to receive or push external resource : #{e}" )
      end
    end
  end

end
