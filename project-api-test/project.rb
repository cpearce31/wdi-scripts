require 'dotenv'
require 'colorize'
require 'curb'
require 'json'
require 'date'

Dotenv.load

def get_schema (resource, username, repo)
  raw_url = "https://raw.githubusercontent.com/#{username}/#{repo}/master/db/schema.rb"
  schema = Curl.get(raw_url).body_str

  fields = {}

  schema.split('create_table ').each do |table|
    if table.lines.first =~ /#{resource}/
      fields_arr = table.lines.select do |line|
        line.strip[0] == 't' &&
          line !~ /created_at/ &&
          line !~ /updated_at/ &&
          line !~ /index/ &&
          line !~ /user_ud/
      end
      fields_arr.each do |field_str|
        f_type, f_name = field_str.strip.delete('"').delete(',').split(/\s+/)
        fields[f_name] = f_type[2..-1]
      end
    end
  end
  fields
end

def build_params (schema, resource)
  params = {
    resource => {}
  }

  schema.each do |f_name, f_type|
    if %(string text).include? f_type.to_s
      params[resource][f_name] = 'foo'
    elsif %(float decimal integer).include? f_type
      params[resource][f_name] = 1
    elsif f_type == 'date'
      params[resource][f_name] = Date.today.to_s
    elsif f_type == 'datetime'
      params[resource][f_name] = DateTime.now.to_s
    elsif f_type == 'boolean'
      params[resource][f_name] = true
    end
  end
  params
end

resource = ARGV[0]
username = ARGV[1]
repo = ARGV[2]

data = build_params(get_schema(resource, username, repo), resource)

resource_id = nil

# CREATE
http_create = Curl.post("#{ENV['URL']}#{resource}s", data.to_json) do |curl|
  curl.headers['Content-Type'] = 'application/json'
  curl.headers['Authorization'] = "Token token=#{ENV['TOKEN']}"
end

if http_create.status !~ /2\d\d/
  abort("It appears there was an error: #{http_create.status}, #{http_create.body_str}".red)
  puts 'Attempted to POST with these params:'
  puts data
else
  puts "POST to #{ENV['URL']}#{resource}s succesful. Response:"
  puts http_create.body_str.green
  if JSON.parse(http_create.body_str)[resource]
    resource_id = JSON.parse(http_create.body_str)[resource]['id']
  end
end

# INDEX
http_index = Curl.get("#{ENV['URL']}/#{resource}s") do |curl|
  curl.headers['Content-Type'] = 'application/json'
  curl.headers['Authorization'] = "Token token=#{ENV['TOKEN']}"
end

if http_index.status != '200 OK'
  abort("It appears there was an error: #{http_index.status}, #{http_index.body_str}".red)
else
  puts "GET to #{ENV['URL']}#{resource}s succesful. Response:"
  puts http_index.body_str.green
end

# SHOW
http_show = Curl.get("#{ENV['URL']}/#{resource}s/#{resource_id}") do |curl|
  curl.headers['Content-Type'] = 'application/json'
  curl.headers['Authorization'] = "Token token=#{ENV['TOKEN']}"
end

if http_show.status != '200 OK'
  abort("It appears there was an error: #{http_show.status}, #{http_show.body_str}".red)
else
  puts "GET to #{ENV['URL']}#{resource}s/#{resource_id} succesful. Response:"
  puts http_show.body_str.green
end

# UPDATE
data[resource].each do |field, val|
  data[resource][field] = 'bar' if val.instance_of? String
  data[resource][field] += 1 if val.is_a? Numeric
  date[resource][field] = false if !!val == val
end

http_update = Curl.patch("#{ENV['URL']}/#{resource}s/#{resource_id}", data.to_json) do |curl|
  curl.headers['Content-Type'] = 'application/json'
  curl.headers['Authorization'] = "Token token=#{ENV['TOKEN']}"
end

if http_update.status !~ /2\d\d/
  abort("It appears there was an error: #{http_update.status}, #{http_update.body_str}".red)
  puts 'Attempted to PATCH with these params:'
  puts data
else
  puts "PATCH to #{ENV['URL']}#{resource}s succesful. Response:"
  puts http_update.body_str.green
end

# USER OWNERSHIP TESTING
malice_signup = {
  credentials: {
    email: 'malice666',
    password: 'foo',
    password_confirmation: 'foo'
  }
}

Curl.post("#{ENV['URL']}/sign-up", malice_signup.to_json) do |curl|
  curl.headers['Content-Type'] = 'application/json'
end

malice_signin = {
  credentials: {
    email: 'malice666',
    password: 'foo'
  }
}

http_signin = Curl.post("#{ENV['URL']}/sign-in", malice_signin.to_json) do |curl|
  curl.headers['Content-Type'] = 'application/json'
end

malice_token = http_signin.body['user']['token']

data[resource].each do |field, val|
  data[resource][field] = 'baz' if val.instance_of? String
  data[resource][field] += 3 if val.is_a? Numeric
  date[resource][field] = true if !!val == val
end

http_malice_update = Curl.patch("#{ENV['URL']}/#{resource}s/#{resource_id}", data.to_json) do |curl|
  curl.headers['Content-Type'] = 'application/json'
  curl.headers['Authorization'] = "Token token=#{malice_token}"
end

if http_malice_update.body_str =~ /Access denied/
  puts 'Malicious PATCH failed due to proper ownership.'
else
  puts 'Malicious PATCH likely succesful. Response:'
  puts http_malice_update.body_str
end

http_malice_destroy = Curl.delete("#{ENV['URL']}/#{resource}s/#{resource_id}") do |curl|
  curl.headers['Authorization'] = "Token token=#{malice_token}"
end

if http_malice_destroy.body_str =~ /Access denied/
  puts 'Malicious DELETE failed due to proper ownership.'
else
  puts 'Malicious DELETE likely succesful. Response:'
  puts http_malice_delete.body_str
end

http_destroy = Curl.delete("#{ENV['URL']}/#{resource}s/#{resource_id}") do |curl|
  curl.headers['Authorization'] = "Token token=#{ENV['TOKEN']}"
end

if http_destroy.status !~ /2\d\d/
  abort("It appears there was an error: #{http_destroy.status}, #{http_destroy.body_str}".red)
else
  puts "DESTROY to #{ENV['URL']}#{resource}s/#{resource_id} with original token succesful."
end
