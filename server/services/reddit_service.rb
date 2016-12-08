class RedditService
  def self.client
    @reddit ||= RedditKit::Client.new 'astute_newt', 'newtnewt'
  end

  def self.question_source_subreddits
    %w(
      askscience askreddit nostupidquestions AskPhotography
    )
    # questions gaming askwomen relationship_advice
    # answers techsupport AskCulinary AskGames AskACountry AskLiteraryStudies AskNetsec AskStatistics
    # AskSciTech Antiques legaladvice  AskComputerScience AskHistory hometheater askdrugs
    # AskScienceFiction AskElectronics asktransgender Teachers AskAcademia dating_advice learnmath
    # LearnJapanese French askphilosophy AskSocialScience AskEngineers InsightfulQuestions TrueAskReddit
    # PoliticalDiscussion booksuggestions
  end

  # def self.current_questions_in subreddit
  #   questions = []

  #   RedditService.client.links(subreddit).each do |link|
  #     link_title = link.title

  #     if QuestionSelectionService.is_a_question? link_title
  #       puts "Found question: #{link_title}"
  #       questions << link_title
  #     else
  #       puts "Discarded question: #{link_title}"
  #     end
  #   end

  #   questions
  # end

  def self.find_and_save_questions
    found_phrasings = []

    RedditService.question_source_subreddits.each do |subreddit|
      RedditService.client.links(subreddit).each do |link|
        link_title = link.title

        if QuestionSelectionService.is_a_question? link_title
          next if QuestionSelectionService.existing_question_match(link_title).present?
          puts "Found question: #{link_title}"

          question = QuestionSelectionService.existing_question_match link_title
          question ||= Question.create

          phrasing = Phrasing.where(question: question, phrasing: link_title).first_or_create
          query = Query.where(phrasing: phrasing, seen_at: link.permalink).first_or_create

          found_phrasings << link_title
        else
          puts "Discarded question: #{link_title}"
        end
      end
    end

    found_phrasings
  end

  # returns '5h1z9m'
  def self.comment_id_from_comment_url url
    url.match('/r/\w+/comments/([^/]+)/')[1]
  # rescue
  #   #todo logging
  #   nil
  end

  def self.link_from_url url
    #todo are all links prefixed with t3_ ?
    puts "Extracting comment ID from #{url}"
    self.client.link 't3_' + self.comment_id_from_comment_url(url)
  # rescue
  #   #todo logging
  #   nil
  end

  # returns newly-posted comment object
  def self.reply_to url, with:, source:
    return nil if url.nil? or with.nil?
    return :archived if with.length > 10000

    link = self.link_from_url url
    if link.present? and with.present?
      response = self.response_template
      response.gsub!('<source>', source)
      response.gsub!('<answer>', SanitationService.fuzz_paragraphs(with).gsub("\n\n", "\n\n>"))

      puts "Responding to #{url} with #{response}."
      self.client.submit_comment(link, response)
    end
  rescue RedditKit::Archived
    :archived
  rescue RedditKit::PermissionDenied
    :archived
  # rescue RedditKit::RateLimited
  #   puts "Rate limited by reddit -- retrying in 60 seconds."
  #   sleep 60
  #   retry
  end

  def self.response_template
    [
      "Hi! I found [a similar question](<source>) asked elsewhere, ",
      "so the answer there might help you:",
      "\n\n",
      "><answer>",
      "\n\n",
      "^(I'm just a bot trying to share the love. Sorry if questions are loose matches right now; i'm working on it!)"
    ].join
  end
end