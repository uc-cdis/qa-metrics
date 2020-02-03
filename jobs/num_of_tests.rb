#!/bin/env ruby
# encoding: utf-8

require 'net/http'
require 'uri'
require 'json'

server = "https://jenkins.planx-pla.net"

SCHEDULER.every '5m', :first_in => 0 do |job|
  url = URI.parse("#{server}/job/qa-metrics/ws/qa-metrics.json")
  http = Net::HTTP.new(url.host, url.port)
  request = Net::HTTP::Get.new(url.request_uri)
  request.basic_auth("themarcelor@gmail.com", ENV['GITHUB_TOKEN'])
  http.use_ssl = (url.scheme == 'https')
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  response = http.request(request)

  # Convert to JSON
  j = JSON[response.body]
  
  send_event('total_num_of_tests', { current: j['total_num_of_tests'].to_i } )
  send_event('num_of_manual_tests', { current: j['num_of_manual_tests'].to_i } )
end
