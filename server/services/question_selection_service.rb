class QuestionSelectionService
  def self.is_a_question? question
    [
      #text.strip[-1] == '?',
      %(who what what's when where why how).include?(question.strip.split(' ')[0].downcase)
    ].all?
  end

  def self.existing_question_match question
    #todo fuzzy matching
    phrasing = Phrasing.find_by_phrasing(question)

    if phrasing.nil?
      nil
    else
      phrasing.question
    end
  end

  def self.unanswered_questions
    Question
      .includes(:phrasings)
      .includes(:answers)
      .where.not(phrasings: { id: nil })
      .where(answers: { id: nil })
  end

  def self.answered_questions
    Question
      .includes(:phrasings)
      .includes(:answers)
      .where.not(phrasings: { id: nil })
      .where.not(answers: { id: nil })
  end

  # Returns a random question we have no answers to
  def self.unanswered_question
    self.unanswered_questions.sample
  end

  # Returns a random question we've found an answer to, but haven't posted that answer back to the
  # question's original query
  def self.answered_question_without_response
    answered_questions = self.answered_questions

    # Filter out answered questions that we've already posted the answer to
    answered_questions
      .includes(:responses)
      .where.not(responses: { id: nil })

    answered_questions.sample
  end
end