class RedditService
  def self.client
    @reddit ||= RedditKit::Client.new 'wizard_of_dong', 'dongdong'
  end

  def self.question_source_subreddits
    %w(askscience nostupidquestions)
  end

  def self.current_questions_in subreddit
    questions = []

    RedditService.client.links(subreddit).each do |link|
      link_title = link.title

      if QuestionSelectionService.is_a_question? link_title
        puts "Found question: #{link_title}"
        questions << link_title
      else
        puts "Discarded question: #{link_title}"
      end
    end

    questions
  end
end