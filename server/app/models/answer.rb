class Answer < ActiveRecord::Base
  belongs_to :question
  has_many :responses
  has_many :queries, through: :question
end
