namespace :coordinator do
  desc "Coordinate the whole thing over IRC"
  task irc: :environment do
    puts "Starting IRC coordinator."

    $irc = nil
    irc_thread = Thread.new do
      $irc = Cinch::Bot.new do
        configure do |c|
          c.nick = "q_coordinator"
          c.realname = "q"
          c.server = "irc.amazdong.com"
          c.channels = [ "#q" ]
        end
      end

      $irc.start
    end

    sleep 10
    output_channel = $irc.channels.first
    output_channel.send "Initializing IRC coordinator."

    while true
      # Fetch new questions
      output_channel.send "Looking for new questions..."

      RedditService.question_source_subreddits.each do |subreddit|
        RedditService.client.links(subreddit).each do |link|
          link_title = link.title

          if QuestionSelectionService.is_a_question? link_title
            next if QuestionSelectionService.existing_question_match(link_title).present?

            output_channel.send "  * #{link_title}"

            question = QuestionSelectionService.existing_question_match link_title
            question ||= Question.create

            phrasing = Phrasing.where(question: question, phrasing: link_title).first_or_create
            query = Query.where(phrasing: phrasing, seen_at: link.url).first_or_create

          end

        end
      end

      output_channel.send "Now monitoring #{QuestionSelectionService.unanswered_questions.count} unanswered questions."
      output_channel.send "#{QuestionSelectionService.answered_questions.count} questions have been answered."

      sleep 5

      # Look for new answers
      output_channel.send "Looking for new answers..."

      unanswered_questions = QuestionSelectionService.unanswered_questions.first(5)
      unanswered_questions.each do |unanswered_question|
        phrasings = unanswered_question.phrasings

        output_channel.send "Looking for answer to question ID #{unanswered_question.id} with #{phrasings.count} phrasings:"
        phrasings.each do |phrasing|
          output_channel.send "  * #{phrasing.phrasing}"

          quora_question, question_url = QuoraService.question_match phrasing.phrasing
          if quora_question.present?
            output_channel.send "Matched [#{phrasing.phrasing}] to [#{quora_question}]."

            unless phrasings.map(&:phrasing).include?(quora_question) && quora_question != phrasing.phrasing
              output_channel.send "Saving Quora's wording as alternate phrasing."
              unanswered_question.phrasings.where(phrasing: quora_question).first_or_create
            end

            output_channel.send "Extracting top answer..."
            top_answer = QuoraService.top_answer question_url
            if top_answer.present?
              output_channel.send "Got answer of length #{top_answer.length}."
              answer = unanswered_question.answers.where(answer: top_answer).first_or_create
            else
              output_channel.send "Question not answered yet; will try again later."
            end
          else
            output_channel.send "Couldn't find a suitable question. [TODO: ask question]"
          end
        end
      end

      # Post answers to queries

      sleep 5

      output_channel.send "Sleeping for 60 seconds."
      sleep 60
    end
  end
end
