releases = Hash.new({ value: 0 })
SCHEDULER.every '1m', :first_in => 0 do |job|
  releases['current'] = { label: '->', value: '2020.03' }
  send_event('current_release', { items: releases.values } )
end
