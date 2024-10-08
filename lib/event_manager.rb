require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'

days_of_week = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
  phone_number.to_s.gsub(/[^\w\s]/,'').gsub(/\s+/, "").rjust(10,"0")[0..9]
end 

def extract_hour(reg_date)
  datetime = DateTime.strptime(reg_date, "%m/%d/%y %H:%M")
  datetime.hour
end 

def extract_day(reg_date)
  datetime = Date.strptime(reg_date, "%m/%d/%y %H:%M")
  datetime.wday
end 

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hours_count = Hash.new(0)
wdays_values = Array.new(0)
days_count = Hash.new(0)
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  phone_number = clean_phone_number(row[:homephone])
  reg_hour = extract_hour(row[:regdate])
  reg_day = extract_day(row[:regdate])

  hours_count[reg_hour] += 1
  days_count[days_of_week[reg_day]] += 1
  
  # save_thank_you_letter(id,form_letter)
end

best_hours = hours_count.max_by { |hour, count| count }
best_days = days_count.max_by { |day, count| count }
puts "best hour for ads: #{best_hours}" 
puts "best day for ads: #{best_days}"