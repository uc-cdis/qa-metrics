#!/bin/env ruby
# encoding: utf-8

require 'net/http'
require 'uri'
require 'json'

server = "https://jenkins.planx-pla.net"

releases = Hash.new({ value: 0 })

SCHEDULER.every '5m', :first_in => 0 do |job|
  url = URI.parse("#{server}/job/qa-metrics/ws/qa-metrics.json")
  http = Net::HTTP.new(url.host, url.port)
  request = Net::HTTP::Get.new(url.request_uri)
  request.basic_auth("themarcelor@gmail.com", ENV['GITHUB_TOKEN'].chomp)
  http.use_ssl = true
  response = http.request(request)

  # Convert to JSON
  j = JSON[response.body]

  releases['current'] = { label: '->', value: j['current_release']  }
  send_event('current_release', { items: releases.values } )
end
