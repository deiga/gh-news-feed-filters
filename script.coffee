on_repo_page = ->
  $(".repohead").length > 0

on_news_feed_page = ->
  $("#dashboard > .news").length > 0


init = ->
  if on_repo_page()
    new RepoPage

  else if on_news_feed_page()
    new NewsFeedPage




# Models


class Event
  constructor: (@caption, @name) ->


class FilterSet
  constructor: (@repo_name) ->

  is_filtered: (event_name) ->
    event_name in @get_items()

  update: (event_name, is_filtered) ->
    s = (e for e in @get_items() when e isnt event_name)
    s.push(event_name) if is_filtered
    @set_items(s)

  key: ->
    "amck-gh-filter" + @repo_name

  pack: (val) ->
    val.join " "

  unpack: (val) ->
    if val? and val isnt ""
      val.split(/\s+/)
    else []

  get_items: ->
    @unpack(localStorage.getItem(@key()))

  set_items: (val) ->
    localStorage.setItem(@key(), @pack(val))




# Views


class RepoPage
  constructor: ->
    filter_set = new FilterSet(@repo_name())
    new FilterButton(filter_set).inject()

  repo_name: ->
    $(".js-current-repository").attr("href")


class NewsFeedPage
  constructor: ->
    new NewsFeedFilter().inject()


class FilterButton
  constructor: (@filter_set) ->

  inject: ->
    element = $(@html())
    @bind_events(element)
    $("li.watch-button-container").after(element)

  click: (element) ->
    @filter_set.update(element.value, element.checked)

  bind_events: (container) ->
    $("table.notifications", container).delegate "input", "change", (event) =>
      @click(event.target)

  html: ->
    """
    <li class="amck-gh-filter context-menu-container js-menu-container">
      <a href="#" class="minibutton switcher js-menu-target"><span>
        Filters
      </span></a>

      <div class="context-pane js-menu-content">
        <a href="javascript:;" class="close js-menu-close"></a>
        <div class="context-title">Filter Events</div>
        <div class="context-body">
          <table class="notifications">
            #{@rows()}
          </table>
          <div class="help">
            Select event types to filter
            them from your news feed
          </div>
        </div>
      </div>
    </li>
    """

  rows: ->
    (@row(e) for e in events).join("\n")

  row: (event) ->
    """
    <tr>
      <td><label for="amck-#{event.name}">#{event.caption}</td>
      <td class="checkbox">#{@checkbox(event)}</td>
    </tr>
    """

  checkbox: (event) ->
    checked = if @filter_set.is_filtered(event.name) then "checked" else ""
    "<input type='checkbox' id='amck-#{event.name}' value='#{event.name}' #{checked}>"


class NewsFeedFilter
  inject: ->
    @rebind_events()
    @inject_counter()
    @apply_to(@$alerts())
    @maybe_load_more()

  inject_counter: ->
    @$news().prepend("""
      <div class="amck-gh-filter-counter">
        Filtered <span>0</span> events
        <a href="">Show all</a>
      </div>
    """)

    @$news().find(".amck-gh-filter-counter a").click (event) =>
      @$news().find(".alert:hidden").show()
      event.preventDefault()

  rebind_events: ->
    @$news().delegate ".ajax_paginate", "click", (event) =>
      event.stopPropagation()
      event.preventDefault()

      link = $(event.target)
      div = link.parent ".ajax_paginate"

      unless div.hasClass "loading"
        div.addClass "loading"

        $.ajax({
          type: "GET"
          url: link.attr "href"

          complete: =>
            div.removeClass "loading"

          success: (data) =>
            new_items = $("<div>").append(data).children()
            @apply_to(new_items)
            div.replaceWith new_items
            @maybe_load_more()
        })

  apply_to: (items) ->
    filtered = 0

    items.each (i, element) =>
      event_name = element.className.replace /alert\s+/, ""
      if @filter_set(element).is_filtered(event_name)
        $(element).css "opacity", 0.4
        $(element).hide()
        filtered++

    @increment_counter(filtered)

  maybe_load_more: ->
    if @$alerts().length < 20
      @$news().find(".ajax_paginate a").click()

  $news: ->
    $("#dashboard > .news")

  $alerts: ->
    @$news().find(".alert:visible")

  increment_counter: (n) ->
    span = @$news().find(".amck-gh-filter-counter span")
    span.html(parseInt(span.html(), 10) + n)

  filter_set: (element) ->
    new FilterSet(@repo_name(element))

  repo_name: (element) ->
    links = $("div.title > a", element)
    $(links[links.length - 1]).attr("href")




events = [
  new Event "Pushed",               "push"
  new Event "Forked",               "fork"
  new Event "Branch/Tag Created",   "create"
  new Event "Branch/Tag Deleted ",  "delete"
  new Event "Commit Commented",     "push"
  new Event "Issue Opened",         "issues_opened"
  new Event "Issue Repened",        "issues_reopened"
  new Event "Issue Commented",      "issues_comment"
  new Event "Issue Closed",         "issues_closed"
  new Event "Watched",              "watch_started"
  new Event "Member Added",         "member_add"
  new Event "Wiki Updated",         "gollum"
]

init()