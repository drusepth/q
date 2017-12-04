namespace :test do
  desc "Test Quora Service with IRC bot"
  task irc: :environment do
  	irc = Cinch::Bot.new do
      configure do |c|
        c.nick = "q"
        c.realname = "q"
        c.server = "irc.amazdong.com"
        c.channels = [ "#fj" ]
      end

      on :message, /q: (.*)/ do |m, message|
        puts "Looking up: #{message}"

        question_match, question_url = QuoraService.question_match message
        puts "Matched question: #{question_match}"
        puts "at #{question_url}"

        top_answer, answerer = QuoraService.top_answer question_url

        if top_answer.nil?
          m.reply "#{m.user}: I have no idea"
        else
          answer_sentences = top_answer.split('.')
          public_answer = answer_sentences.shift
          private_answer = '..'

          answer_sentences.each do |sentence|
            if public_answer.length < 240
              public_answer += '.' + sentence
            else
              private_answer += '.' + sentence
            end
          end

          m.reply "#{m.user}: #{public_answer}."
          m.user.reply "#{private_answer}" if private_answer.length > '..'.length
        end
      end
    end

    irc.start
  end
end
