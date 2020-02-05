releases = Hash.new({ value: 0 })
SCHEDULER.every '1m', :first_in => 0 do |job|
  releases['current'] = { label: '->', value: 'integration202002' }
  send_event('current_release', { items: releases.values } )
end
