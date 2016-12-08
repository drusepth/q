namespace :questions do
  desc "I sense a soul in search of answers"
  task find: :environment do
    RedditService.find_and_save_questions
  end

  desc "Post unanswered questions in more places to hopefully get an answer"
  task post: :environment do
  end

end
