class QuoraService

  def self.question_match question
    sleep 10

    response = HTTParty.get(search_path(question), headers: self.headers)

    doc = Nokogiri::HTML(response.body)
    match = doc.at('a[class="question_link"]')

    if match
      [
        match.text(),
        'https://www.quora.com' + match['href']
      ]
    else
      [nil, nil]
    end
  end

  def self.top_answer question_url
    sleep 10

    response = HTTParty.get(question_url, headers: self.headers)
    doc = Nokogiri::HTML(response.body)

    doc.at('.Answer').at('div').children()[1].children().at('.rendered_qtext').text()
  rescue
    nil
  end

  private

  def self.headers
    {
      'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Encoding' => 'gzip, deflate, sdch, br',
      'Accept-Language' => 'en-US,en;q=0.8',
      'Cache-Control' => 'no-cache',
      'Connection' => 'keep-alive',
      'Host' => 'www.quora.com',
      #'Origin' => 'https://www.quora.com',
      #'Referer' => 'https://www.quora.com',
      'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.82 Safari/537.36',
      'Upgrade-Insecure-Requests' => '1'
    }
  end

  def self.search_path query
    #todo url sanitize
    "https://www.quora.com/search?type=question&q=#{URI::encode query}"
  end
end
