require 'net/http'
require 'json'

HOST = "minisculuschallenge.com"
ALPHABET = [
  "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
  "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
  "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
  "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
  "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
  ".", ",", "?", "!", "'", "\"", " "
]

def get_question(path, attribute = 'question')
  uri = URI("http://#{HOST}#{path}")
  JSON.parse(Net::HTTP.get_response(uri).body)[attribute]
end

def submit_answer(path, answer)
  Net::HTTP.start(HOST) do |http|
    headers = {
      'Accept'       => 'application/json',
      'Content-Type' => 'application/json',
    }

    http.put(path, {answer: answer}.to_json, headers)['Location']
  end
end

def split_and_join(message)
  message.chars.map {|c| ALPHABET[yield ALPHABET.index(c)] }.join
end

def encode(message, settings)
  previous = 0

  split_and_join(message) do |current|
    shift(current, previous, settings, :+).tap { previous = current }
  end
end

def decode(message, settings)
  previous = 0

  split_and_join(message) do |current|
    shift(current, previous, settings, :-).tap {|current| previous = current }
  end
end

def crack(code)
  [*0..9].product([*0..9]).each do |w1, w2|
    if (decoded = decode(code, wheel1: w1, wheel2: w2, wheel3: 1)) =~ /FURLIN/
      break decoded
    end
  end
end

def shift(current_index, previous_index, settings, operator)
  [
    current_index,
    settings.fetch(:wheel1, 0),
    settings.fetch(:wheel2, 0) * -2,
    settings.fetch(:wheel3, 0) *  2 * previous_index
  ].inject(operator) % ALPHABET.size
end

location = Net::HTTP.get_response(URI("http://#{HOST}/start"))['Location']

location = submit_answer(location,
  encode(get_question(location), wheel1: 6))

location = submit_answer(location,
  encode(get_question(location), wheel1: 9, wheel2: 3))

location = submit_answer(location,
  encode(get_question(location), wheel1: 4, wheel2: 7, wheel3: 1))

location = submit_answer(location,
  decode(get_question(location), wheel1: 7, wheel2: 2, wheel3: 1))

puts crack(get_question(location, 'code'))
