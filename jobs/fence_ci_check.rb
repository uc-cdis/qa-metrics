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
  request['Authorization'] = "token #{ENV['GITHUB_TOKEN'].chomp}"
  http.use_ssl = true
  response = http.request(request)
  http_response = JSON[response.body]
end


server = "https://api.github.com"
repo = "fence"
# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '4h', :first_in => 0 do |job|
  pull_requests = httpGetter("#{server}/repos/uc-cdis/#{repo}/pulls\?state=all\&per_page=100")
  total_prs = 0
  total_failures = 0
  last_force_merge = ""
  pull_requests.each do |pr|
    puts("#{pr['number']} - #{pr['updated_at']}")    
    updated_at = Time.parse(pr['updated_at'])
    # only PRs from the last week
    puts("updated_at: #{updated_at}")
    puts("7d ago: #{Time.now - (3600 * 24 * 7)}")
    if updated_at >= Time.now - (3600 * 24 * 7)
      total_prs = total_prs + 1
      recent_pr = httpGetter("#{server}/repos/uc-cdis/#{repo}/pulls/#{pr['number']}")
      recent_pr_status = httpGetter("#{recent_pr['statuses_url']}")
      next unless recent_pr_status.length() > 0
      puts("PR ##{pr['number']} -> state: #{recent_pr_status[0]['state']}")
      if recent_pr_status[0]['state'] != 'success' and recent_pr["base"]["ref"] == "master"
        total_failures = total_failures + 1
        if recent_pr.has_key? 'merged_at' and recent_pr['merged_at'] != nil
          last_force_merge = "PR ##{pr['number']} -> Merged by: #{recent_pr['user']['login']}"
        end
      end
    end
  end

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
