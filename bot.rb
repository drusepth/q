require 'cinch'
require 'redditkit'
require 'thread'

# Queue of questions found on reddit to go look up answers to
$questions_found_on_reddit = Queue.new

# Queue of questions that we've found an answer on Quora to, ready to post back to reddit
$questions_to_post_answers_to = Queue.new

# A fifo queue for matching LUI answers in order on IRC
$irc_question_last_asked = Queue.new

# Global hash keyed off questionss that includes the reddit comment ID they were seen at, and the answer we fetched from Quora
$question_details = Hash.new({id: nil, answer: nil})

# reddit interface
$reddit = RedditKit::Client.new 'wizard_of_dong', 'dongdong'

# irc interface
$irc = nil

def debug message, channel=:debug
  puts message
end

def is_a_question? text
  return [
    #text.strip[-1] == '?',
    %(who what what's when where why how).include?(text.strip.split(' ')[0].downcase)
  ].all?
end

def is_a_good_question? text
  #todo do some sanitation to weed out shitty questions
  #todo d/q questions w/ expletives
  true && is_a_question?(text)
end

def answered_on_quora? question
  #todo hit up quora for this shit
  quora_question_phrasing = nil
  quora_top_answer = nil

  # for now, just ask on IRC for all question matching (return :maybe)
  [:maybe, quora_question_phrasing, quora_top_answer]
end

reddit_scraping_thread = Thread.new do
  question_subreddit_sources = %w(askscience nostupidquestions)

  while true
    debug "Fetching Quora questions"
    question_subreddit_sources.each do |subreddit|
      $reddit.links(subreddit).each do |link|
        link_title = link.title
        if is_a_good_question?(link_title)
          puts "Found question: #{link_title}"
          $question_details[link_title][:id] = link.id
          $questions_found_on_reddit << link_title
        else
          puts "Discarded question: #{link_title}"
        end
      end
    end

    debug "Sleeping 60 before requesting reddit again"
    sleep 60
  end
end

reddit_posting_thread = Thread.new do
  while true
    question = $questions_to_post_answers_to.pop

    reply_id, answer = $question_details[question]
    $reddit.comment(reply_id).reply(answer)
  end
end

quora_thread = Thread.new do
  while true
    debug "Waiting for a question to query Quora with"
    question = $questions_found_on_reddit.pop
    debug "Trying to match '#{question} on Quora"

    quora_response, top_question, top_answer = answered_on_quora? question

    if quora_response == true
      # Question is answered on Quora, lets go post the answer back to reddit
      $question_details[question][:answer] = top_answer
    elsif quora_response == false
      # Question either doesn't exist on Quora, or isn't answered -- do nothing
    elsif quora_response == :maybe
      # Not sure if the top Quora search result is a direct mapping -- ask on IRC
      $question_details[question][:answer] = "#{top_question}: #{top_answer}"

      $irc.channels.first.send "Are [#{top_question}] and [#{question}] asking the same thing?"
      $irc_question_last_asked << question
    end
  end
end

irc_thread = Thread.new do
  $irc = Cinch::Bot.new do
    configure do |c|
      c.nick = "q"
      c.realname = "q"
      c.server = "irc.amazdong.com"
      c.channels = [ "#q" ]
    end

    on :message, /q: yes/ do |m, message|
      question = $irc_question_last_asked.pop # don't be a dick

      # The questions are the same, so post the answer to reddit
      $questions_to_post_answers_to << question
    end

    on :message, /q: no/ do |m, message|
      # Questions are not the same, so just pop off that bitch
      $irc_question_last_asked.pop
    end
  end

  $bot.start
end

[
  reddit_scraping_thread,
  #reddit_posting_thread,
  quora_thread,
  #irc_thread
].map(&:join)
