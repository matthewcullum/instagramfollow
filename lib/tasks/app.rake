namespace :app do
  desc "TODO"
  task reset: :environment do
    Rake::Task['db:migrate:reset'].invoke
    Rake::Task['db:test:prepare'].invoke
    `redis-cli flushall`
  end

end
