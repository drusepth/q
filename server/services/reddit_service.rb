class RedditService
  def self.client
    @reddit ||= RedditKit::Client.new 'wizard_of_dong', 'dongdong'
  end

  def self.question_source_subreddits
    %w(askscience nostupidquestions)
  end
end