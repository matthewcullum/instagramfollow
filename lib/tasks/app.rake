namespace :app do
  desc "TODO"
  task reset: :environment do
    Rake::Task['db:migrate:reset'].invoke
    `redis-cli flushall`
  end

end
