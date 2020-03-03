# Switcher widget written by Juha Mustonen / SC5

# Switches (reloads to another address) the dashboards in periodic manner
# <div id="container" data-switcher-interval="10000" data-switcher-dashboards="dashboard1 dashboard2">
#   <%= yield %>
# </div>
#
class DashboardSwitcher
  constructor: () ->
    @dashboardNames = []
    # Collect the dashboard names from attribute, if provided (otherwise skip switching)
    names = $('[data-switcher-dashboards]').first().attr('data-switcher-dashboards') || ''
    if names.length > 1
      # Get names separated with comma or space
      @dashboardNames = (name.trim() for name in names.split(/[ ,]+/).filter(Boolean))

  start: (interval=60000) ->
    interval = parseInt(interval, 10)
    @maxPos = @dashboardNames.length - 1

    # Skip switching if no names defined
    if @dashboardNames.length == 0
      return

    # Take the dashboard name from that last part of the path
    pathParts = window.location.pathname.split('/')
    @curName = pathParts[pathParts.length - 1]
    @curPos = @dashboardNames.indexOf(@curName)

    # If not found, default to first
    if @curPos == -1
      @curPos = 0
      @curName = @dashboardNames[@curPos]

    # instantiate switcher controls for countdown and manual switching
    @switcherControls = new DashboardSwitcherControls(interval, @)
    @switcherControls.start() if @switcherControls.present()

    @startLoop(interval)

  startLoop: (interval) ->
    self = @
    @handle = setTimeout(() ->
      # Increase the position or reset back to zero
      self.curPos += 1
      if self.curPos > self.maxPos
        self.curPos = 0

      # Switch to new dashboard
      self.curName = self.dashboardNames[self.curPos]
      window.location.pathname = "/#{self.curName}"

    , interval)

  stopLoop: () ->
    clearTimeout @handle

  currentName: () ->
    @curName

  nextName: () ->
    @dashboardNames[@curPos + 1] || @dashboardNames[0]

  previousName: () ->
    @dashboardNames[@curPos - 1] || @dashboardNames[@dashboardNames.length - 1]


# Switches (hides and shows) elements within on list item
# <li switcher-interval="3000">
#   <div widget-1></div>
#   <div widget-2></div>
#   <div widget-3></div>
# </li>
#
# Supports optional switcher interval, defaults to 5sec
class WidgetSwitcher
  constructor: (@elements) ->
    @$elements = $(@elements)


  start: (interval=5000, control) ->
    self = @
    
    @maxPos = @$elements.length - 1;
    @curPos = Math.min(1, @maxPos)

    # Show only first at start
    self.$elements.slice(1).hide()

    # instantiate switcher controls for countdown and manual switching
    @switcherControls = new WidgetSwitcherControls(interval, control, @)
    if @switcherControls.present()
      @switcherControls.start() 
    else
      @startLoop(interval)


  startLoop: (interval) ->
    self = @
    @handle = setInterval(()->
        self.next()

    , parseInt(interval, 10))


  next: () ->
    # Hide all at first - then show the current and ensure it uses table-cell display type
    @$elements.hide()
    $(@$elements[@curPos]).show().css('display', 'table-cell')

    # Increase the position or reset back to zero
    @curPos += 1
    if @curPos > @maxPos
      @curPos = 0


  prev: () ->
    @$elements.hide()
    previous = @curPos - 2
    previous = @maxPos if previous == -1
    previous = @maxPos - 1  if previous == -2

    $(@$elements[previous]).show().css('display', 'table-cell')

    @curPos -= 1
    if @curPos < 0
      @curPos = @maxPos

  stopLoop: () ->
    clearInterval(@handle)

#  currentName: () ->
#    @curName
#
  nextName: () ->
    $(@elements[@curPos]).attr("data-switcher-name")
        
    #@dashboardNames[@curPos + 1] || @dashboardNames[0]
#
#  previousName: () ->
#    @dashboardNames[@curPos - 1] || @dashboardNames[@dashboardNames.length - 1]


class WidgetSwitcherControls
  arrowContent = "&#65515;"
  stopTimerContent = "stop timer"
  startTimerContent = "start timer"

  constructor: (interval=60000,id, widgetSwitcher) ->
    @currentTime = parseInt(interval, 10)
    @interval = parseInt(interval, 10)
    @$elements = $("##{id}")
    @widgetSwitcher = widgetSwitcher
    @incrementTime = 1000 # refresh every 1000 milliseconds
    @arrowContent = @$elements.data('next-widget-content') || WidgetSwitcherControls.arrowContent
    @stopTimerContent = @$elements.data('stop-widget-timer-content') || WidgetSwitcherControls.stopTimerContent
    @startTimerContent = @$elements.data('start-widget-timer-content') || WidgetSwitcherControls.startTimerContent
    @

  present: () ->
    @$elements.length

  start: () ->
    @addElements()
    @$timer = $.timer(@updateTimer, @incrementTime, true)
    @updateWidgetName()

  addElements: () ->
    template = @$elements.find('widget-name-template')
    if template.length
      @$nextWidgetNameTemplate = template
      @$nextWidgetNameTemplate.remove()
    else
      @$nextWidgetNameTemplate = $("<widget-name-template>Next widget: $nextName in </widget-name-template>")
    @$nextWidgetNameContainer = $("<span id='dc-wid-switcher-next-name'></span>")
    @$countdown = $("<span id='dc-wid-switcher-countdown'></span>")
    @$manualPrev = $("<span id='dc-wid-switcher-prev' class='fa fa-backward'></span>").
      html(@arrowContent).
      click () =>
        @switchWidget(false)
    @$manualNext = $("<span id='dc-wid-switcher-next' class='fa fa-forward'></span>").
      html(@arrowContent).
      click () =>
        @switchWidget()
    @$switcherStopper = $("<span id='dc-wid-switcher-pause-reset' class='fa fa-pause'></span>").
      html(@stopTimerContent).
      click(@pause)
    @$elements.
      append(@$nextWidgetNameContainer).
      append(@$countdown).
      append(@$manualPrev).
      append(@$switcherStopper).
      append(@$manualNext)

  pad: (number, length) =>
    str = "#{number}"
    while str.length < length
      str = "0#{str}"
    str

  formatTime: (time) ->
    time = time / 10;
    min = parseInt(time / 6000, 10)
    sec = parseInt(time / 100, 10) - (min * 60)

    formattedMin = if min > 0 then @pad(min, 2) else "00"
    formattedSec = @pad(sec, 2)
    "#{formattedMin}:#{formattedSec}"


  pause: () =>
    @$timer.toggle()
    if @isRunning()
      @$switcherStopper.removeClass('fa-pause').addClass('fa-play').html(@startTimerContent)
    else
      @$switcherStopper.removeClass('fa-play').addClass('fa-pause').html(@stopTimerContent)

  isRunning: () =>
    @$switcherStopper.hasClass('fa-pause')

  resetCountdown: (next=true) ->
    @switchWidget(next)
    # Stop and reset timer
    @$timer.stop().play(true)

  switchWidget: (next=true) ->
    # Get time from form
    newTime = @interval
    if newTime > 0
      @currentTime = newTime

    if next
      @widgetSwitcher.next()
    else
      @widgetSwitcher.prev();

    @updateWidgetName()
    @updateTimeString()

  updateTimer: () =>
    @updateTimeString()
    # If timer is complete, trigger alert
    if @currentTime is 0
      #@pause()
      @resetCountdown()
      return

    # Increment timer position
    @currentTime -= @incrementTime
    if @currentTime < 0
      @currentTime = 0

  updateWidgetName: () ->
    @$nextWidgetNameContainer.html(
      @$nextWidgetNameTemplate.html().replace('$nextName', @widgetSwitcher.nextName())
    )

  updateTimeString: () ->
    timeString = @formatTime(@currentTime)
    @$countdown.html(timeString)        
# Adds a countdown timer to show when next dashboard will appear
# TODO:
#   - show the name of the next dashboard
#   - add controls for manually cycling through dashboards
class DashboardSwitcherControls
  arrowContent = "&#65515;"
  stopTimerContent = "stop timer"
  startTimerContent = "start timer"

  constructor: (interval=60000, dashboardSwitcher) ->
    @currentTime = parseInt(interval, 10)
    @interval = parseInt(interval, 10)
    @$elements = $('#dc-switcher-controls')
    @dashboardSwitcher = dashboardSwitcher
    @incrementTime = 1000 # refresh every 1000 milliseconds
    @arrowContent = @$elements.data('next-dashboard-content') || DashboardSwitcherControls.arrowContent
    @stopTimerContent = @$elements.data('stop-timer-content') || DashboardSwitcherControls.stopTimerContent
    @startTimerContent = @$elements.data('start-timer-content') || DashboardSwitcherControls.startTimerContent
    @

  present: () ->
    @$elements.length

  start: () ->
    @addElements()
    @$timer = $.timer(@updateTimer, @incrementTime, true)

  addElements: () ->
    template = @$elements.find('dashboard-name-template')
    if template.length
      @$nextDashboardNameTemplate = template
      @$nextDashboardNameTemplate.remove()
    else
      @$nextDashboardNameTemplate = $("<dashboard-name-template>Next dashboard: $nextName in </dashboard-name-template>")
    @$nextDashboardNameContainer = $("<span id='dc-switcher-next-name'></span>")
    @$countdown = $("<span id='dc-switcher-countdown'></span>")
    @$manualSwitcher = $("<span id='dc-switcher-next' class='fa fa-forward'></span>").
      html(@arrowContent).
      click () =>
        location.href = "/#{@dashboardSwitcher.nextName()}"
    @$switcherStopper = $("<span id='dc-switcher-pause-reset' class='fa fa-pause'></span>").
      html(@stopTimerContent).
      click(@pause)
    @$elements.
      append(@$nextDashboardNameContainer).
      append(@$countdown).
      append(@$manualSwitcher).
      append(@$switcherStopper)

  formatTime: (time) ->
    time = time / 10;
    min = parseInt(time / 6000, 10)
    sec = parseInt(time / 100, 10) - (min * 60)
    "#{(if min > 0 then @pad(min, 2) else "00")}:#{@pad(sec, 2)}"

  pad: (number, length) =>
    str = "#{number}"
    while str.length < length
      str = "0#{str}"
    str

  pause: () =>
    @$timer.toggle()
    if @isRunning()
      @dashboardSwitcher.stopLoop()
      @$switcherStopper.removeClass('fa-pause').addClass('fa-play').html(@startTimerContent)
    else
      @dashboardSwitcher.startLoop @currentTime
      @$switcherStopper.removeClass('fa-play').addClass('fa-pause').html(@stopTimerContent)

  isRunning: () =>
    @$switcherStopper.hasClass('fa-pause')

  resetCountdown: () ->
    # Get time from form
    newTime = @interval
    if newTime > 0
      @currentTime = newTime

    # Stop and reset timer
    @$timer.stop().once()

  updateTimer: () =>
    # Update dashboard name
    @$nextDashboardNameContainer.html(
      @$nextDashboardNameTemplate.html().replace('$nextName', @dashboardSwitcher.nextName())
    )
    # Output timer position
    timeString = @formatTime(@currentTime)
    @$countdown.html(timeString)

    # If timer is complete, trigger alert
    if @currentTime is 0
      @pause()
      @resetCountdown()
      return

    # Increment timer position
    @currentTime -= @incrementTime
    if @currentTime < 0
      @currentTime = 0

# Expose our API
Dashing.DashboardSwitcher = DashboardSwitcher
Dashing.WidgetSwitcher = WidgetSwitcher
Dashing.DashboardSwitcherControls = DashboardSwitcherControls
Dashing.WidgetSwitcherControls = WidgetSwitcherControls

# Dashboard loaded and ready
Dashing.on 'ready', ->
  # If multiple widgets per list item, switch them periodically
  $('.gridster li').each (index, listItem) ->
    $listItem = $(listItem)
    # Take the element(s) right under the li
    $widgets = $listItem.children('div')
    if $widgets.length > 1
      switcher = new WidgetSwitcher $widgets
      interval = $listItem.attr('data-switcher-interval')
      control = $listItem.attr('data-switcher-control')
      switcher.start(interval or 5000, control)

  # If multiple dashboards defined (using data-swticher-dashboards="board1 board2")
  $container = $('#container')
  ditcher = new DashboardSwitcher()
  ditcher.start($container.attr('data-switcher-interval') or 60000)

