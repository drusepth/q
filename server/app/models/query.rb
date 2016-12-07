class Query < ActiveRecord::Base
  belongs_to :phrasing
  has_many :responses

  delegate :question, :to => :phrasing, :allow_nil => true
end
