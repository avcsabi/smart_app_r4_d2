desc "Get access token (test) Usage: 'VERBOSE=0 rake get_access_token'"
task :get_access_token do
  require 'auth'
  Rails.logger ||= Logger.new($stdout)
  Auth.verbose = true unless %w[0 no n].include?(ENV['VERBOSE'].to_s.downcase)
  puts 'Get access token...'
  token = Auth.get_access_token('system/Patient.read system/AllergyIntolerance.read')
  puts "Access token: #{token.pretty_inspect}"
end
