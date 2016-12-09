class SanitationService
  def self.fuzz_paragraphs text
    paragraphs = []
    paragraph = []
    text.split('. ').each do |sentence|
      paragraph << sentence + '.  '

      if paragraph.length > 1 + rand(2)
        paragraphs << paragraph.join('.') + ' '
        paragraph = []
      end
    end

    if paragraphs.empty?
      paragraphs << text
    end
    paragraphs.join "\n\n"
  end
end