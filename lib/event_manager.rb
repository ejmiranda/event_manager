# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode, digits)
  zipcode.to_s.rjust(digits, '0')[0..digits - 1]
end

def legislators_by_zipcode(zipcode) # rubocop:disable Metrics/MethodLength
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_phone_number(phone_number)
  phone_number = phone_number.split('').select { |char| /\d+/.match?(char) }.join
  phone_number = phone_number[1..] if phone_number[0] == '1'
  if phone_number.size != 10
    'Bad Number'
  else
    [3, 7].each { |idx| phone_number.insert(idx, '-') }
    phone_number
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

content = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

content.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode], 5)
  legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_number(row[:homephone])

  form_letter = erb_template.result(binding)

  puts phone_number

  # save_thank_you_letter(id, form_letter)
end
