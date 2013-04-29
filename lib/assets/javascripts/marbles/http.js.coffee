##
# Rewrite Marbles HTTP lib
# TODO: merge back into Marbles codebase
# - requires updating Marbles.HTTP.Client

URI = Marbles.HTTP.URI
Marbles.HTTP = class HTTP
  @URI = URI

  @active_requests: {}
  MAX_NUM_RETRIES: 3

  constructor: (args) ->
    [@method, @url, params, @body, @headers, callback, @middleware] = [args.method.toUpperCase(), args.url, args.params, args.body, args.headers, args.callback, args.middleware || []]

    if @method in ['GET', 'HEAD']
      @key = "#{@method}:#{@url}:#{JSON.stringify(@params || '{}')}"
      if request = HTTP.active_requests[@key]
        return request.callbacks.push(callback)
      else
        HTTP.active_requests[@key] = @

      @retry_count = 0

      @retry_arguments = _.inject(arguments, ((memo, i)-> memo.push(i); memo), [])
      @retry = =>
        http = new HTTP @retry_arguments...
        http.retry_count = @retry_count
        http.callbacks = @callbacks

    @callbacks = if callback then [callback] else []

    @request = new HTTP.Request

    uri = new HTTP.URI @url
    uri.mergeParams(params)
    @host = uri.hostname
    @path = uri.path
    @port = uri.port
    @url = uri.toString()

    @sendRequest()

  setHeader: => @request.setHeader(arguments...)
  setHeaders: (headers) =>
    for header, value of headers
      @setHeader(header, value)

  sendRequest: =>
    return unless @request

    @request.open(@method, @url)
    @setHeaders(@headers) if @headers

    for middleware in @middleware
      middleware.processRequest?(@)

    @request.on 'complete', (xhr) =>
      delete HTTP.active_requests[@key] if @key

      if (@method in ['GET', 'HEAD']) && (xhr.status == 503 or xhr.status == 0) and (@retry_count < @MAX_NUM_RETRIES)
        @retry_count += 1
        @retry()
        return

      @response_data = xhr.response

      for middleware in @middleware
        middleware.processResponse?(@, xhr)

      for fn in @callbacks
        continue unless typeof fn == 'function'
        fn(@response_data, xhr)

    @request.send(@body)

  class @Request
    request_headers: {}

    constructor: ->
      @callbacks = {}

      XMLHttpFactories = [
        -> new XMLHttpRequest()
        -> new ActiveXObject("Msxml2.XMLHTTP")
        -> new ActiveXObject("Msxml3.XMLHTTP")
        -> new ActiveXObject("Microsoft.XMLHTTP")
      ]

      @xmlhttp = false
      for fn in XMLHttpFactories
        try
          @xmlhttp = fn()
        catch e
          continue
        break

      @xmlhttp.onreadystatechange = @stateChanged

    stateChanged: =>
      return if @xmlhttp.readyState != 4
      @trigger 'complete'

    setHeader: (key, val) =>
      @request_headers[key] = val
      @xmlhttp.setRequestHeader(key,val)

    on: (event_name, fn) =>
      @callbacks[event_name] ||= []
      @callbacks[event_name].push fn

    trigger: (event_name) =>
      @callbacks[event_name] ||= []
      for fn in @callbacks[event_name]
        if typeof fn == 'function'
          fn(@xmlhttp)
        else
          console?.warn "#{event_name} callback is not a function"
          console?.log fn

    open: (method, url) => @xmlhttp.open(method, url, true)

    send: (data) =>
      return @trigger('complete') if @xmlhttp.readyState == 4
      @xmlhttp.send(data)
