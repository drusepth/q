class Question < ActiveRecord::Base
  has_many :phrasings
  has_many :answers
  has_many :queries, through: :phrasings
end
