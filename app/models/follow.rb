class Follow < ActiveRecord::Base
  def self.where_finished
    where({finished: true}).all
  end

  def self.where_unfinished
    where({finished: false}).all
  end
end
