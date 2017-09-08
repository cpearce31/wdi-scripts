require 'dotenv'
require 'colorize'
require 'curb'
require 'json'

Dotenv.load

# first argument is a predefined ENV var in .env
# second argument is a value
# EX. to change email, write_to_env('EMAIL', 'me@mail.com')
def write_to_env (var_name, value)
  data = File.read('.env')
  updated_data = data.gsub(/#{var_name}='\K.+/, "#{value}'")
  File.open('.env', 'w') do |file|
    file.write(updated_data)
  end
end

puts 'What is your email?'.blue
email = $stdin.gets.chomp
abort('Must enter an email'.red) if email.empty?
write_to_env('EMAIL', email)

puts 'What is your password?'.blue
password = $stdin.gets.chomp
abort('Must enter a password'.red) if password.empty?
write_to_env('PASSWORD', password)

puts 'What is the API\'s URL?'.blue
api_url = $stdin.gets.chomp
abort('Must enter a url'.red) if api_url.empty?
api_url += '/' unless api_url[-1] == '/'
write_to_env('URL', api_url)

data = {
  credentials: {
    email: email,
    password: password,
    password_confirmation: password
  }
}

http = Curl.post("#{api_url}/sign-up", data.to_json) do |curl|
  curl.headers['Content-Type'] = 'application/json'
end

if http.status != '201 Created'
  abort("It appears there was an error: #{http.status}, #{http.body_str}")
else
  puts "Successful sign up #{http.body_str}"
end
