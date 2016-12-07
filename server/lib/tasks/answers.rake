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
        top_answer = QuoraService.top_answer question_url
        if top_answer.present?
          puts "Got answer of length #{top_answer.length}."
          answer = unanswered_question.answers.where(answer: top_answer).first_or_create
        else
          puts "Question not answered yet; will try again later."
        end
      else
        puts "Couldn't find a suitable Quora question."
      end
    end
  end

  desc "TODO"
  task post: :environment do

  end

end
