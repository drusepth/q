class Phrasing < ActiveRecord::Base
  belongs_to :question
  has_many :queries
end
