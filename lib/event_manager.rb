require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'Invalid zipcode. You can find your rep by going to www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phonenumber(phone)
  phone.to_s.delete!('^0-9')
  if phone.length == 10
    phone
  elsif phone.length == 11 and phone[0] == '1'
    phone[1..10]
  else
    'Invalid Phone Number'
  end
end

def ext_hours(regdate)
  Time.strptime(regdate,"%m/%d/%y %k:%M").hour
end

def count_hours(hours)
  hour_count = Hash.new(0)
  hours.each {|hour| hour_count[hour] += 1}
  hour_count.max_by { |hour,occur| occur}
end

def ext_day(regdate)
  Date::DAYNAMES[Date.strptime(regdate, "%m/%d/%y %k:%M").wday]
end

def count_days(days)
  day_count = Hash.new(0)
  days.each {|day| day_count[day] += 1}
  day_count.max_by { |day,occur| occur}
end

puts 'EventManager Initialized!'

contents = CSV.open(
  'event_attendees.csv', 
  headers: true,
  header_converters: :symbol
)
template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hours = []
days = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone = clean_phonenumber(row[:homephone])
  hours << ext_hours(row[:regdate])
  days << ext_day(row[:regdate])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end

regs_by_hour = count_hours(hours)
regs_by_day = count_days(days)
puts "At most, there were #{regs_by_hour[1]} registrations per hour, between #{regs_by_hour[0]}:00 and #{regs_by_hour[0]+1}:00."
puts "The registrations occurred most commonly on #{regs_by_day[0]}s."