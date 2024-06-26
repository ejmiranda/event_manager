# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

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
    phone_number.insert(0, '(')
    phone_number.insert(4, ')')
    phone_number.insert(8, '-')
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

puts "\nEventManager initialized."

content = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

reg_times = []

content.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode], 5)
  legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_number(row[:homephone])
  form_letter = erb_template.result(binding)

  reg_times << Time.strptime(row[:regdate], '%m/%d/%y %H:%M')

  # Uncomment the line below to save the HTML letters to /output
  # save_thank_you_letter(id, form_letter)
end

def highest_entries(arr)
  counted_arr = arr.each_with_object({}) do |entry, count|
    count[entry] = arr.count(entry)
  end
  (counted_arr.sort_by { |_key, value| value }).reverse.to_h
end

puts "\nHighest Registration Hours\n\n"
hrh = highest_entries(reg_times.map(&:hour))
hrh.each do |hour, qty| # hrh is a Hash, so hour = key and qty = value
  time = Time.new(1977, 5, 25, hour, 0, 0)
  puts "#{time.strftime('%I %p')}: #{qty}"
end

puts "\nHighest Registration Days\n\n"
hrd = highest_entries(reg_times.map(&:wday))
hrd.each do |wday, qty| # hrd is a Hash, so wday = key and qty = value
  puts "#{Date::DAYNAMES[wday]}: #{qty}"
end
