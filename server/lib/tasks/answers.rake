namespace :answers do
  desc "Picks a random question and goes to look for answers to it"
  task find: :environment do
    unanswered_question = QuestionSelectionService.unanswered_question
    phrasings = unanswered_question.phrasings

    puts "Looking for answer to question ID #{unanswered_question.id} with #{phrasings.count} phrasings:"
    puts phrasings.map(&:phrasing).to_sentence

    puts "Trying to match against an answered Quora question..."
    phrasings.each do |phrasing|
      quora_question, question_url = QuoraService.question_match phrasing.phrasing
      if quora_question.present?
        puts "Matched [#{phrasing.phrasing}] to [#{quora_question}]."

        unless phrasings.map(&:phrasing).include? quora_question
          puts "Saving Quora's wording as alternate phrasing."
          unanswered_question.phrasings.where(phrasing: quora_question).first_or_create
        end

        puts "Extracting top answer..."
        top_answer, answerer = QuoraService.top_answer question_url
        if top_answer.present?
          puts "Got answer of length #{top_answer.length}."
          answer = unanswered_question.answers.where(
            answer: top_answer,
            source: question_url,
            answerer: answerer
          ).first_or_create
        else
          puts "Question not answered yet; will try again later."
        end
      else
        puts "Couldn't find a suitable Quora question."
      end
    end
  end

  desc "Looks for answers to all unanswered questions"
  task find_all: :environment do
    QuestionSelectionService.unanswered_questions.each do |unanswered_question|
      phrasings = unanswered_question.phrasings

      puts "Looking for answer to question ID #{unanswered_question.id} with #{phrasings.count} phrasings:"
      puts phrasings.map(&:phrasing).to_sentence

      puts "Trying to match against an answered Quora question..."
      phrasings.each do |phrasing|
        quora_question, question_url = QuoraService.question_match phrasing.phrasing
        if quora_question.present?
          puts "Matched [#{phrasing.phrasing}] to [#{quora_question}]."

          unless phrasings.map(&:phrasing).include? quora_question
            puts "Saving Quora's wording as alternate phrasing."
            unanswered_question.phrasings.where(phrasing: quora_question).first_or_create
          end

          puts "Extracting top answer..."
          top_answer, answerer = QuoraService.top_answer question_url
          if top_answer.present?
            puts "Got answer of length #{top_answer.length}."
            answer = unanswered_question.answers.where(
              answer: top_answer,
              source: question_url,
              answerer: answerer
            ).first_or_create
          else
            puts "Question not answered yet; will try again later."
          end
        else
          puts "Couldn't find a suitable Quora question."
        end
      end
    end
  end

  desc "Picks a random answered question and posts a response with the answer"
  task post: :environment do
    puts "Choosing a random answered question we haven't responded to yet..."

    question = QuestionSelectionService.answered_question_without_response
    if question.present?
      puts "Selected question with #{question.phrasings.count} phrasings:"
      puts question.phrasings.map(&:phrasing).to_sentence

      question.queries.each do |query|
        # If this query has already been responded to, skip it
        next if query.responses.any?

        answer = question.answers.sample
        puts "Responding to query seen at #{query.seen_at} with answer of length #{answer.answer.length}."

        comment = RedditService.reply_to(query.seen_at, answer: answer)

        # Log response so we don't post this answer again
        if comment == :archived
          puts "Question was archived. Marking it responded to so we can ignore it."
          Response.where(question: question, answer: answer, query: query, seen_at: 'archived').first_or_create
        elsif comment.present?
          puts "Logging response at #{comment.link_id}"
          Response.where(question: question, answer: answer, query: query, seen_at: comment.link_id).first_or_create
        else
          puts "Couldn't post to reddit for some reason."
        end
      end

    else
      puts "No answered questions are waiting for a response."
    end
  end

end
