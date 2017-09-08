require 'dotenv'
require 'colorize'
require 'curb'
require 'json'

Dotenv.load

def write_to_env (var_name, value)
  data = File.read('.env')
  updated_data = data.gsub(/#{var_name}='\K.+/, "#{value}'")
  File.open('.env', 'w') do |file|
    file.write(updated_data)
  end
end

data = {
  credentials: {
    email: ENV['EMAIL'],
    password: ENV['PASSWORD'],
    password_confirmation: ENV['PASSWORD']
  }
}

http = Curl.post("#{ENV['URL']}/sign-in", data.to_json) do |curl|
  curl.headers['Content-Type'] = 'application/json'
end

if http.status != '200 OK'
  abort("It appears there was an error: #{http.status}, #{http.body_str}")
else
  response = JSON.parse(http.body)['user']
  write_to_env('UID', response['id'])
  write_to_env('TOKEN', response['token'])
  puts "Successful sign in for #{response['email']}"
end
