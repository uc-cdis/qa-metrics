require 'time'
require 'date'
require 'net/http'
require 'openssl'
require 'uri'
require 'json'

def httpGetter(url_str)
  url = URI.parse(url_str)
  http = Net::HTTP.new(url.host, url.port)
  request = Net::HTTP::Get.new(url.request_uri)
  request['Authorization'] = "token #{ENV['GITHUB_TOKEN'].dup}"
  http.use_ssl = (url.scheme == 'https')
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  response = http.request(request)
  j = JSON[response.body]
end

server = "https://api.github.com"
repo = "fence"

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '4h', :first_in => 0 do |job|
  j = httpGetter("#{server}/repos/uc-cdis/#{repo}/pulls\?state=all\&per_page=100")
   
  total_prs = 0
  total_failures = 0
  last_force_merge = ""
   
  j.each_with_index { |idx, pr|
    puts("#{j[pr]['number']} - #{j[pr]['updated_at']}")    
    updated_at = Time.parse(j[pr]['updated_at'])
    # only PRs from the last week
    puts("updated_at: #{updated_at}")
    puts("7d ago: #{Time.now - (3600 * 24 * 7)}")
    if updated_at >= Time.now - (3600 * 24 * 7)
      total_prs = total_prs + 1
      j2 = httpGetter("#{server}/repos/uc-cdis/#{repo}/pulls/#{j[pr]['number']}")
      j3 = httpGetter("#{j2['statuses_url']}")
      next unless j3.length() > 0
      puts("PR ##{j[pr]['number']} -> state: #{j3[0]['state']}")
      if j3[0]['state'] != 'success'
        total_failures = total_failures + 1
        if j2.has_key? 'merged_at' and j2['merged_at'] != nil
          last_force_merge = "PR ##{j[pr]['number']} -> Merged by: #{j2['user']['login']}"
        end
      end
    end
  }

  puts("total prs: #{total_prs}")
  puts("failures: #{total_failures}")
  total_success = total_prs - total_failures
  success_rate = total_prs == 0 ? 100.00 : ((total_success.to_f/total_prs.to_f)*100).round(2)
  puts("success rate: #{success_rate}%")

  stats = Hash.new({ value: 0 })
  stats['num_of_prs'] = { label: 'num of PRs', value: "#{total_prs}" }
  stats['num_of_failures'] = { label: 'total failures', value: "#{total_failures}" }
  stats['success_rate'] = { label: 'success rate', value: "#{success_rate}%" }
  stats['last_force_merge'] = { label: 'Last force merge', value: "#{last_force_merge}" }

  send_event('fence_ci_stats', { items: stats.values } )
end
