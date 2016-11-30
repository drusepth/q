namespace :questions do
  desc "I sense a soul in search of answers"
  task find: :environment do
    client = RedditService.client

    RedditService.question_source_subreddits.each do |subreddit|
      RedditService.client.links(subreddit).each do |link|
        link_title = link.title

        if QuestionSelectionService.is_a_question? link_title
          puts "Found question: #{link_title}"

          question = QuestionSelectionService.existing_question_match link_title
          question ||= Question.create

          phrasing = Phrasing.where(question: question, phrasing: link_title).first_or_create
          query = Query.where(phrasing: phrasing, seen_at: link.url).first_or_create

        else
          puts "Discarded question: #{link_title}"
        end

      end
    end
  end

  desc "Post unanswered questions in more places to hopefully get an answer"
  task post: :environment do
  end

end
