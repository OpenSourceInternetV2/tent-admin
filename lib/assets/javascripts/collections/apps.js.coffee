TentAdmin.Collections.Apps = class AppsCollection extends Marbles.Collection
  @model: TentAdmin.Models.App
  @id_mapping_scope: ['entity']
  @collection_name: 'apps_collection'

  constructor: ->
    super
    @set('entity', TentAdmin.config.meta.content.entity)

  pagination: {}

  fetchNext: (options = {}) =>
    return false unless @pagination.next
    next_params = Marbles.History::parseQueryParams(@pagination.next)
    @fetch(next_params, _.extend({ append: true }, options))

  fetch: (params = {}, options = {}) =>
    complete = (res, xhr) =>
      models = null
      if xhr.status in [200...300]
        models = @fetchSuccess(params, options, res, xhr)
        options.success?(@, models, res, xhr)
        @trigger('fetch:success', models, res, xhr, params, options)
        # success
      else
        options.failure?(@, res, xhr)
        @trigger('fetch:failure', res, xhr, params, options)
      options.complete?(@, models, res, xhr)
      @trigger('fetch:complete', models, res, xhr, params, options)

    params = _.extend {
      entity: TentAdmin.config.meta.content.entity
      types: [@constructor.model.post_type]
    }, params

    TentAdmin.tent_client.post.list(params: params, callback: complete)

  fetchSuccess: (params, options, res, xhr) =>
    @pagination = _.extend({
      first: @pagination.first
      last: @pagination.last
    }, res.pages)

    # reject any apps that don't ref an app auth
    data = _.reject res.posts, (_post) ->
      !_post.refs?.length || !_.find(_post.refs, ((_r) -> _r.type == TentAdmin.Models.AppAuth.post_type.toString()))

    models = if options.append
      @appendJSON(data)
    else if options.prepend
      @prependJSON(data)
    else
      @resetJSON(data)

    # get app-auth ref for each app model
    for app in models
      auth_ref = _.find app.refs, (_ref) ->
        _ref.type == TentAdmin.Models.AppAuth.post_type.toString()

      auth_json = _.find res.refs, (_post) ->
        _post.id == auth_ref.post

      app.auth = TentAdmin.Models.AppAuth.find(id: auth_json.id, entity: auth_json.entity, fetch: false)
      app.auth ?= new TentAdmin.Models.AppAuth(auth_json)

    models

  buildModel: (json) =>
    @constructor.model.find(
      id: json.id
      entity: json.entity
      fetch: false
    ) || new @constructor.model(json)

  resetJSON: (json, options = {}) =>
    @model_ids = []
    models = @appendJSON(json, silent: true)
    @trigger('reset', models) unless options.silent
    models

  appendJSON: (json, options = {}) =>
    return [] unless json?.length

    models = for attrs in json
      model = @buildModel(attrs)
      @model_ids.push(model.cid)
      model

    @trigger('append', models) unless options.silent

    models

  prependJSON: (json, options = {}) =>
    return [] unless json?.length

    models = for i in [json.length-1..0]
      attrs = json[i]
      model = @buildModel(attrs)
      @model_ids.unshift(model.cid)
      model

    @trigger('prepend', models) unless options.silent

    models

