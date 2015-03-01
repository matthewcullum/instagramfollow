redis_url = ENV['REDIS_URL']

$redis = Redis.new url: redis_url