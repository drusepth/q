class RedditService
  def self.client
    @reddit ||= RedditKit::Client.new 'astute_newt', 'newtnewt'
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

  # returns '5h1z9m'
  def self.comment_id_from_comment_url url
    url.match('/r/\w+/comments/([^/]+)/')[1]
  rescue
    #todo logging
    nil
  end

  def self.link_from_url url
    #todo are all links prefixed with t3_ ?
    self.client.link 't3_' + self.comment_id_from_comment_url(url)
  end

  # returns newly-posted comment object
  def self.reply_to url, with:
    link = self.link_from_url url

    self.client.submit_comment(link, with)
  end
end