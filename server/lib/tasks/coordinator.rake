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
      output_channel.send "Looking for new questions. Found the following new ones:"

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
      output_channel.send "We've found answers to #{QuestionSelectionService.answered_questions.count} questions."
      output_channel.send "#{QuestionSelectionService.answered_questions_without_response.count} (answered) questions are waiting for us to respond to."

      sleep 30

      # Look for new answers
      output_channel.send "Looking for new answers..."

      unanswered_questions = QuestionSelectionService.unanswered_questions.sample(10)
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

      sleep 30

      # Post answers to queries

      output_channel.send "Choosing a random answered question we haven't responded to yet..."

      question = QuestionSelectionService.answered_question_without_response
      if question.present?
        output_channel.send "Selected question with #{question.phrasings.count} phrasings:"
        question.phrasings.map(&:phrasing).each { |phrasing| output_channel.send "  * #{phrasing}" }

        question.queries.each do |query|
          # If this query has already been responded to, skip it
          next if query.responses.any?

          answer = question.answers.sample
          output_channel.send "Responding to query seen at #{query.seen_at} with answer of length #{answer.answer.length}."

          begin
            output_channel.send "Formatting answer for reddit..."

            formatted_answer = SanitationService.fuzz_paragraphs answer.answer
            comment = RedditService.reply_to query.seen_at, with: formatted_answer

            # Log response so we don't post this answer again
            if comment == :archived
              puts "Question was archived. Marking it responded to so we can ignore it."
              Response.where(question: question, answer: answer, query: query, seen_at: 'archived').first_or_create
            elsif comment.present?
              output_channel.send "Posted comment with ID #{comment.link_id}"
              Response.where(question: question, answer: answer, query: query, seen_at: comment.link_id).first_or_create
            else
              output_channel.send "Unknown error while commenting to reddit. See the logs."
            end

          rescue RedditKit::RateLimited
            output_channel.send "Currently rate-limited by Reddit -- will try again later."
            sleep 20
          end
        end

      else
        output_channel.send "No answered questions are waiting for a response."
      end

      sleep 10

      output_channel.send "All done with this cycle. Sleeping for 60 seconds."
      sleep 180
    end
  end
end
