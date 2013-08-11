root = exports ? this

root.Morandi = {}

class root.Morandi.EditMode
  addTo: (editor) ->
    @editor = editor
  removeFrom: (editor) ->

class root.Morandi.Straighten extends root.Morandi.EditMode
  addTo: (editor) ->
    super
    @editor.shape = new createjs.Shape()
    @editor.stage.addChild(@editor.shape)

  removeFrom: (editor) ->
    @editor.stage.removeChild(@editor.shape)
    super

  setValues: (values) ->
    values ?= {}

    values.rotation ?= 0
    rotationValueRad = Math.abs(values.rotation * Math.PI / 180.0)
    scale = @editor.baseScale * @editor.bmp.image.height / ((@editor.bmp.image.width * Math.sin(rotationValueRad)) +
              (@editor.bmp.image.height * Math.cos(rotationValueRad)))

    @editor.bmp.scaleX = scale
    @editor.bmp.scaleY = scale
    @editor.bmp.rotation = values.rotation

    ratio = 6.0/4.0
    rh = (@editor.bmp.image.height) / ((ratio * Math.sin(rotationValueRad)) + Math.cos(rotationValueRad))

    rh = rh * scale / @editor.baseScale # Scale down to fit scaled down rect
    rw = rh * ratio

    x = (@editor.canvas.width / 2) - (@editor.baseScale * rw / 2)
    y = (@editor.canvas.height / 2) - (@editor.baseScale * rh / 2)
    w = rw * @editor.baseScale
    h = rh * @editor.baseScale
    
    @editor.shape.graphics = new createjs.Graphics().beginStroke('#00ff00').rect(x, y, w, h)
  update: ->
    #

class root.Morandi.Colour extends root.Morandi.EditMode
  setValues: (values) ->
    values ?= {}
    values.brightness ?= 0
    values.contrast ?= 0
    values.saturation ?= 0
    values.hue ?= 0
    values.redChannel ?= 255
    values.greenChannel ?= 255
    values.blueChannel ?= 255

    values.blurX ?= 0
    values.blurY ?= 0
    cm = new createjs.ColorMatrix()
    cm.adjustColor(values.brightness, values.contrast, values.saturation, values.hue)

    @colorFilter = new createjs.ColorMatrixFilter(cm)
    @blurFilter = new createjs.BoxBlurFilter(values.blurX, values.blurY, 2)
    @redChannelFilter = new createjs.ColorFilter(values.redChannel/255,1,1,1)
    @greenChannelFilter = new createjs.ColorFilter(1,values.greenChannel/255,1,1)
    @blueChannelFilter = new createjs.ColorFilter(1,1,values.blueChannel/255,1)


  update: ->
    return unless @editor.bmp
    @editor?.bmp?.filters = [@colorFilter, @blurFilter, @redChannelFilter, @greenChannelFilter, @blueChannelFilter]
    @editor?.bmp?.updateCache()

  addTo: (editor) ->
    @editor = editor
    super

  removeFrom: (editor) ->
    @editor?.bmp?.filters = []
    @editor?.bmp?.updateCache()
    super

class root.MorandiEditor
  constructor: (canvas) ->
    @baseScale = 2
    @stage = new createjs.Stage(canvas)
    @canvas = canvas
    @setEngine(new root.Morandi.Colour())

  loadedImage: (img) ->
    @stage.removeChild(@bmp) if @bmp

    scale1 = @canvas.width / img.width
    scale2 = @canvas.height / img.height
    if scale1 < scale2
      @baseScale = scale1
    else
      @baseScale = scale2

    @bmp = new createjs.Bitmap(img)
    @bmp.regX = img.width / 2
    @bmp.regY = img.height / 2
    @bmp.scaleX = @baseScale
    @bmp.scaleY = @baseScale
    @bmp.cache(0, 0, img.width, img.height)
    @stage.addChild(@bmp)
    @stage.setChildIndex(@bmp, 0)

    $(@canvas).trigger('loaded', @bmp)

    @setValues()

  loadImage: (src) ->
    @url = src
    @settings = {}
    img = new Image()
    img.onload = (=> @loadedImage(img))
    img.src = src

  setEngine: (engine) ->
    @engine.removeFrom(@) if @engine
    @engine = engine
    @engine.addTo(@)

  setValues: (values) ->
    values ?= {}

    # Check image is centered
    @bmp.x = @canvas.width / 2
    @bmp.y = @canvas.height / 2
    @bmp.scaleX = @baseScale
    @bmp.scaleY = @baseScale
    @bmp.rotation = 0

    @engine.setValues(values)
    @update()
    
  update: ->
    @engine.update()
    @stage.update()
