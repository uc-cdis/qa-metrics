#!/bin/env ruby
# encoding: utf-8

require 'net/http'
require 'openssl'
require 'uri'
require 'json'

server = "https://jenkins.planx-pla.net"

SCHEDULER.every '30s', :first_in => 0 do |job|
  url = URI.parse("#{server}/job/list_selected_namespaces_per_PR/lastSuccessfulBuild/execution/node/3/ws/prChecks.json")
  http = Net::HTTP.new(url.host, url.port)
  request = Net::HTTP::Get.new(url.request_uri)
  github_token = ENV['GITHUB_TOKEN'].dup
  request.basic_auth 'PlanXCyborg', github_token.chomp
  http.use_ssl = true
  response = http.request(request)

  # Convert to JSON
  j = JSON[response.body]
  
  hrows = [
    { cols: [ {value: 'Repo'}, {value: 'Pull Request'}, {value: 'Jenkins namespace'}, {value: 'started by'} ] }
  ]

  rows = []
  j.keys.each { |pr|
    rows << { cols: [ { value: j[pr]['repo'] }, { value: pr }, { value: j[pr]['namespace'] }, { value: j[pr]['by'] } ] }
  }

  send_event('my-table', { hrows: hrows, rows: rows } )
end
