#!/usr/bin/env ruby

require 'aws-sdk'
require 'parseconfig'
require 'fileutils'
require 'date'

profile = ARGV[0]
username = ARGV[1]
roll = false

# For some reason parseconfig does not seem to like ~ on my dev machine.
AWS_CONFIG_FILE = "/home/ubuntu/.aws/credentials"

puts "\nStarting key roll process"
if !profile || !username
  abort("Missing Arguments please provide a profile identifier and user to roll.")
elsif !File.readable?(AWS_CONFIG_FILE)
  abort("Missing aws creds or permissions problem.")
end

puts "\nBacking up file"
filename = AWS_CONFIG_FILE
FileUtils.copy(filename, filename + "-" + Time.now.strftime('%Y-%m-%d_%H-%M-%S'))
config = ParseConfig.new(AWS_CONFIG_FILE)

#puts config.inspect
targetkey = config.params[profile]['aws_access_key_id']
targetsecret = config.params[profile]['aws_secret_access_key']

Aws.config.update(region: 'us-east-1')
Aws.config.update({credentials: Aws::Credentials.new(targetkey,targetsecret)})

puts "\nConnecting to AWS"
iam = Aws::IAM::Client.new

resp = iam.list_access_keys({user_name: username})

resp.access_key_metadata.each do |k|
  if k.create_date.to_date < DateTime.now - 60
    puts "Found expiring key for #{username}: #{k.access_key_id}, #{k.create_date}"
    roll = true
  end
end

if roll == true
  puts "\nCreating new key for #{username}"
  resp = iam.create_access_key({
    user_name: username
  })
  
  new_access_key_id = resp.access_key.access_key_id
  new_secret_access_key = resp.access_key.secret_access_key
  
  puts "New Key: #{new_access_key_id}"
  puts "New Secret: #{new_secret_access_key}"
  sleep 15
end

unless new_access_key_id.nil? || new_secret_access_key.nil?
  puts "\Testing new key for #{username}"
  Aws.config.update({credentials: Aws::Credentials.new(new_access_key_id,new_secret_access_key)})

  resp = iam.list_access_keys({user_name: username})
  unless resp.nil?
    puts "\New keys for #{username} are good, clearing old keys"
    iam.delete_access_key(user_name: username, access_key_id: targetkey)
    
    puts "\Updating credentials file"
    config.add_to_group(profile, 'aws_access_key_id', new_access_key_id)
    config.add_to_group(profile, 'aws_secret_access_key', new_secret_access_key)
    
    #puts "New Config: #{config.inspect}"
    file = File.open(filename, 'w')
    config.write(file, false)
    file.close
    
  else
    puts "Something went wrong!"
  end
else
  puts "Something went wrong!"
end