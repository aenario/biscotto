Method     = require './method'
Variable   = require './variable'
MetaMethod = require '../meta/method'

module.exports = class Mixin extends require('../entity')

  @looksLike: (node) ->
    node.constructor.name == 'Assign' && node.value?.base?.properties?

  @is: (node) ->
    node.documentation?.mixin

  @isConcernSection: (node) ->
    node.constructor.name == 'Assign' &&
    node.value?.constructor.name == 'Value' &&
    (
      node.variable.base.value == 'ClassMethods' ||
      node.variable.base.value == 'InstanceMethods'
    )

  constructor: (@environment, @file, @node) ->
    [@name, @selfish] = @fetchName()

    @documentation = @node.documentation
    @methods       = []
    @variables     = []

    for property in @node.value.base.properties
      # Recognize assigned code on the mixin
      @concern = true if @constructor.isConcernSection(property)

    if @concern
      @classMethods = []
      @instanceMethods = []

  linkify: ->
    super

    @grabMethods @methods, @node

    if @concern
      for property in @node.value.base.properties
        # Recognize concerns as inner mixins
        if property.value?.constructor.name is 'Value'
          switch property.variable.base.value
            when 'ClassMethods'
              @grabMethods @classMethods, property

            when 'InstanceMethods'
              @grabMethods @instanceMethods, property

  grabMethods: (container, node) ->
    for property in node.value.base.properties
      if property.entities?
        for entity in property.entities
          # Foo =
          #   foo: ->
          container.push entity if entity instanceof Method

  effectiveMethods: (type) ->
    methods = []

    for method in @methods
      methods.push(MetaMethod.fromMethodEntity method, type: type)

    if @documentation.methods
      for method in @documentation.methods
        methods.push(MetaMethod.fromDocumentationMethod method, type: type)

    methods

  effectiveInclusionMethods: ->
    @effectiveMethods('dynamic')

  effectiveExtensionMethods: ->
    @effectiveMethods('static')

  effectiveConcernMethods: ->
    methods = []

    for method in @classMethods
      methods.push(MetaMethod.fromMethodEntity method, type: 'static')

    for method in @instanceMethods
      methods.push(MetaMethod.fromMethodEntity method, type: 'dynamic')

    methods

  inspect: ->
    {
      file:            @file.path
      name:            @name
      concern:         @concern
      documentation:   @documentation?.inspect()
      selfish:         @selfish
      methods:         @methods.map (x) -> x.inspect()
      classMethods:    @classMethods?.map (x) -> x.inspect()
      instanceMethods: @instanceMethods?.map (x) -> x.inspect()
      variables:       @variables.map (x) -> x.inspect()
    }
