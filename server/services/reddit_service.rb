class RedditService
  def self.client
    @reddit ||= RedditKit::Client.new 'astute_newt', 'newtnewt'
  end

  def self.question_source_subreddits
    %w(
      automation singularity futurology
      medievalworldproblems physicsjokes circlejerk ShittyAnimalFacts gamedev SelfDrivingCars
      askscience askreddit nostupidquestions AskPhotography chrome chromecast
      questions gaming google apple android homeautomation startups overpopulation
      AskCulinary AskGames AskACountry AskLiteraryStudies AskNetsec AskStatistics
      AskSciTech Antiques legaladvice  AskComputerScience AskHistory hometheater askdrugs
      AskScienceFiction AskElectronics asktransgender Teachers AskAcademia learnmath
      LearnJapanese French askphilosophy AskSocialScience AskEngineers trees marijuana
       booksuggestions explainlikeimfive GamePhysics BasicIncome
      correctmeifwrong outoftheloop politics worldnews sports videos television showerthoughts
      crazyideas food cooking science jokes gadgets music mildlyinteresting news TwoXChromosomes
      TrollXChromosomes The_Donald GetMotivated books DIY philosophy lifeprotips
      funny history morbidquestions

      dinghysailing sailing boats cars
    ) + %w(
      PoliticalDiscussion answers nutrition
    )
  end

  def self.find_and_save_questions
    found_phrasings = []

    RedditService.question_source_subreddits.each do |subreddit|
      begin
        puts "Searching #{subreddit}:"
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
            #puts "Discarded question: #{link_title}"
          end
        end
      rescue RedditKit::PermissionDenied
        next
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
  def self.reply_to url, answer:
    return nil if url.nil? || answer.nil?
    return :archived if answer.answer.length > 10000

    link = self.link_from_url url
    if link.present? && answer.answer.present?
      response = self.response_template
      response.gsub!('<source>', answer.source)
      response.gsub!('<answerer>', answer.answerer)
      response.gsub!('<answer>', answer.answer.gsub("\n\n", "\n\n>"))

      puts "Responding to #{url} with #{response}."
      self.client.submit_comment(link, response)
    end
  rescue RedditKit::Archived
    puts "Thread was archived"
    :archived
  rescue RedditKit::PermissionDenied
    puts "Permission Denied -- we're probably banned from this subreddit?"
    :archived
  rescue RedditKit::RateLimited
    puts "We're rate limited by reddit."
    nil
  # rescue RedditKit::RateLimited
  #   puts "Rate limited by reddit -- retrying in 60 seconds."
  #   sleep 60
  #   retry
  end

  def self.response_template
    [
      "Hi! I found [a similar question](<source>?share=1) asked elsewhere, ",
      "so the top answer there (from <answerer>) might be of interest:",
      "\n\n",
      "><answer>",
      "\n\n",
      "^(I'm just a bot trying to share the love and help people get questions answered faster, and from more people. ",
      "I hope it helps, human!)"
    ].join
  end
end
