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

  def self.unanswered_question
    Question.includes(:answers).where(answers: { id: nil }).sample
  end
end