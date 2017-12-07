require 'rack/request'
require 'redis'

REDIS = Redis.new(url: ENV['REDIS_URL'])

run -> (env) {
  known_plates = REDIS.smembers('known_plates')
  params = Rack::Request.new(env).params

  if params.fetch('token') == ENV.fetch('SLACK_VERIFICATION_TOKEN')
    input = params.fetch('text').split(/\s+/).compact.reject(&:empty?)

    if input.first == 'add'
      input.shift
      REDIS.sadd('known_plates', *input)
      body = "Added #{input.join(",")}"
    elsif input.first == 'remove'
      input.shift
      REDIS.srem('known_plates', *input)
      body = "Removed #{input.join(",")}"
    else
      plates = input

      if plates.empty?
        body = "Known plates:\n\n#{known_plates.join("\n")}\n\nAdd more with `/plates add PLATE1 PLATE2 …`"
      else
        unknown_plates = plates - known_plates

        if unknown_plates.empty?
          body = "They're all ours!"
        else
          body = "Not ours: #{unknown_plates.join(', ')}"
        end
      end
    end

    [200, {}, [body]]
  else
    [401, {}, ['Not authorized']]
  end
}
