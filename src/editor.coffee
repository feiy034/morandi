root = exports ? this

root.Morandi =
  DEFAULT_RATIO: 6.0/4.0
  largestAspectRectangle: (ratio, width, height) ->
    r_ratio = width / height
    if r_ratio < ratio # constrain by width
      bw = width
      bh = width / ratio
      y  = (height - bh) / 2
      rect = { x : 0, y : y, width: bw, height: bh }
    else # constrain by height
      bh = height
      bw = height * ratio
      x  = (width - bw) / 2
      rect = { x : x, y : 0, width: bw, height: bh }

  roundedRectangle: (cr, x1, y1, x2, y2, x_radius=4, y_radius=null) ->
    width = x2-x1
    height = y2-y1
    y_radius ?= x_radius

    x_radius = width / 2 if (x_radius * 2) > width
    y_radius = height / 2 if (y_radius * 2) > height
      
    xr1 = x_radius
    xr2 = x_radius / 2.0
    yr1 = y_radius
    yr2 = y_radius / 2.0
    
    #cr.new_path
    cr.mt(x1 + xr1, y1)
    cr.lt(x2 - xr1, y1)
    cr.bt(x2 - xr2, y1, x2, y1 + yr2, x2, y1 + yr1)
    cr.lt(x2, y2 - yr1)
    cr.bt(x2, y2 - yr2, x2 - xr2, y2, x2 - xr1, y2)
    cr.lt(x1 + xr1, y2)
    cr.bt(x1 + xr2, y2, x1, y2 - yr2, x1, y2 - yr1)
    cr.lt(x1, y1 + yr1)
    cr.bt(x1, y1 + yr2, x1 + xr2, y1, x1 + xr1, y1)
    cr.cp


class root.Morandi.EditMode
  @applyTo: (editor) ->
    # noop
  addTo: (editor) ->
    @editor = editor
  removeFrom: (editor) ->
  className: ->
    @constructor.name


class root.Morandi.Border extends root.Morandi.EditMode
  @applyTo: (editor) ->

  addTo: (editor) ->
    editor.border = new createjs.Shape()
    editor.stage.addChild(editor.border)
    super

  removeFrom: (editor) ->
    @editor.stage.removeChild(@editor.border)
    delete @editor.border
    super

  setValues: (values) ->
    values ?= {}

    values['border-style'] ?= ''
    values['background-style'] ?= ''

    scale = @editor.baseScale * 0.85
    @editor.bmp.scaleX = scale
    @editor.bmp.scaleY = scale
    @editor.bmp.rotation = values.straighten

    ratio = @editor.ratio ? Morandi.DEFAULT_RATIO
    rh = (@editor.bmp.image.height)

    rh = rh * scale / @editor.baseScale # Scale down to fit scaled down rect
    rw = rh * ratio

    x = (@editor.canvas.width / 2) - (@editor.baseScale * rw / 2)
    y = (@editor.canvas.height / 2) - (@editor.baseScale * rh / 2)
    w = rw * @editor.baseScale
    h = rh * @editor.baseScale

    @editor.bmp.clip = null
    switch values['border-style']
      when 'square'
        x -= 20
        y -= 20
        w += 40
        h += 40
      when 'retro'
        clip = new createjs.Graphics()
        Morandi.roundedRectangle(clip, 0, 0, @editor.bmp.image.width, @editor.bmp.image.height, 30)
        @editor.bmp.clip = clip
        x -= 20
        y -= 20
        w += 40
        h += 40

    g = new createjs.Graphics()

    switch values['background-style'] ? 'white'
      when 'white'
        g.f(createjs.Graphics.getRGB(255, 255, 255))
      when 'black'
        g.f(createjs.Graphics.getRGB(0, 0, 0))
      when 'dominant'
        colorThief = new ColorThief()
        col = colorThief.getColor(@editor.bmp.image)
        g.f(createjs.Graphics.getRGB(col[0], col[1], col[2]))


    g.rect(x, y, w, h)

    @editor.border.graphics = g
  update: ->
    @editor.stage.setChildIndex(@editor.border, 0)
    #

class root.Morandi.Rotation extends root.Morandi.EditMode

class root.Morandi.Crop extends root.Morandi.EditMode
  addTo: (editor) ->
    super
    @editor.shape = new createjs.Shape()
    @editor.stage.addChild(@editor.shape)

  removeFrom: (editor) ->
    @editor.stage.removeChild(@editor.shape)
    super

  setValues: (values) ->
    values ?= {}

    values.zoom ?= 1.0

    @editor.bmp.scaleX = values.zoom
    @editor.bmp.scaleY = values.zoom
    @editor.bmp.rotation = 0

    ratio = @editor.ratio ? Morandi.DEFAULT_RATIO
    rh = (@editor.bmp.image.height)
    rh = rh * values.zoom / @editor.baseScale # Scale down to fit scaled down rect
    rw = rh * ratio

    x = (@editor.canvas.width / 2) - (@editor.baseScale * rw / 2)
    y = (@editor.canvas.height / 2) - (@editor.baseScale * rh / 2)
    w = rw * @editor.baseScale
    h = rh * @editor.baseScale
    
    @editor.shape.graphics = new createjs.Graphics().beginStroke('#00ff00').rect(x, y, w, h)

  update: ->
    @editor.stage.setChildIndex(@editor.shape, 1)
    #


class root.Morandi.Straighten extends root.Morandi.EditMode
  addTo: (editor) ->
    super
    @editor.shape = new createjs.Shape()
    @editor.stage.addChild(@editor.shape)

  removeFrom: (editor) ->
    @editor.stage.removeChild(@editor.shape)
    @editor.bmp.rotation = 0
    super

  setValues: (values) ->
    values ?= {}

    values.straighten ?= 0
    rotationValueRad = Math.abs(values.straighten * Math.PI / 180.0)
    scale = @editor.baseScale * @editor.bmp.image.height / ((@editor.bmp.image.width * Math.sin(rotationValueRad)) +
              (@editor.bmp.image.height * Math.cos(rotationValueRad)))

    @editor.bmp.scaleX = scale
    @editor.bmp.scaleY = scale
    @editor.bmp.rotation = values.straighten

    ratio = @editor.ratio ? Morandi.DEFAULT_RATIO
    rh = (@editor.bmp.image.height) / ((ratio * Math.sin(rotationValueRad)) + Math.cos(rotationValueRad))

    rh = rh * scale / @editor.baseScale # Scale down to fit scaled down rect
    rw = rh * ratio

    x = (@editor.canvas.width / 2) - (@editor.baseScale * rw / 2)
    y = (@editor.canvas.height / 2) - (@editor.baseScale * rh / 2)
    w = rw * @editor.baseScale
    h = rh * @editor.baseScale
    
    @editor.shape.graphics = new createjs.Graphics().beginStroke('#00ff00').rect(x, y, w, h)

  update: ->
    @editor.stage.setChildIndex(@editor.shape, 1)
    #

class root.Morandi.SimpleColourFX extends root.Morandi.EditMode
  setValues: (values) ->
    values ?= {}
    values.fx ?= 'colour'
    @filters = []

    switch values.fx
      when 'colour'
      else

        switch values.fx
          when 'greyscale'
            cm = new createjs.ColorMatrix()
            cm.adjustColor(0, 0, -100, 0)

            @filters.push new createjs.ColorMatrixFilter(cm)
          when 'sepia'
            cm = new createjs.ColorMatrix()
            cm.adjustColor(0, 0, -50, 0)

            @filters.push new createjs.ColorMatrixFilter(cm)
            @filters.push new createjs.ColorFilter(1,1,1,1, 25, 5, -25)
          when 'bluetone'
            cm = new createjs.ColorMatrix()
            cm.adjustColor(0, 0, -50, 0)

            @filters.push new createjs.ColorMatrixFilter(cm)
            @filters.push new createjs.ColorFilter(1,1,1,1, -10, 5, 25)

  update: ->
    return unless @editor.bmp
    @editor?.bmp?.filters = @filters ? []
    @editor?.bmp?.updateCache()

  addTo: (editor) ->
    @editor = editor
    super

  removeFrom: (editor) ->
    @editor?.bmp?.filters = []
    @editor?.bmp?.updateCache()
    super


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

    @realWidth = img.width
    @realHeight = img.height
    scale1 = @canvas.width / img.width
    scale2 = @canvas.height / img.height
    if scale1 < scale2
      @baseScale = scale1
    else
      @baseScale = scale2

    @img = img
    if @baseScale < 1.0
      cCopy = document.createElement("canvas")
      cContext     = cCopy.getContext("2d")
      cCopy.width  = @baseScale * img.width
      cCopy.height = @baseScale * img.height
      cContext.drawImage(img, 0, 0, img.width, img.height, 0, 0, cCopy.width, cCopy.height)
      img = cCopy
      @baseScale = 1.0

    @bmp = new createjs.Bitmap(img)
    @bmp.regX = img.width / 2
    @bmp.regY = img.height / 2
    @bmp.scaleX = @baseScale
    @bmp.scaleY = @baseScale
    @bmp.cache(0, 0, img.width, img.height)
    @stage.addChild(@bmp)

    $(@canvas).trigger('loaded', @bmp)

    @setRatio(@ratio) if @ratio
    @setValues(@values ? {})

  preprocessImage: () ->
    for engineClass in Morandi.Engines
      return if engineClass.name == @engine?.className()
  setRatio: (ratio) ->
    @ratio = ratio
    return unless @img

    cratio = @canvas.width / @canvas.height
    iratio = @img.width / @img.height

    x = y = 0

    largest = Morandi.largestAspectRectangle(ratio, @img.width, @img.height)

    scale1 = @canvas.height / largest.height
    scale2 = @canvas.width / largest.width

    scale = scale1
    scale = scale2 if scale2 < scale1

    img = document.createElement("canvas")
    cr = img.getContext("2d")
    img.width = largest.width * scale
    img.height = largest.height * scale
    cr.drawImage(@img, largest.x, largest.y, largest.width, largest.height, 0, 0, img.width, img.height)
    @baseScale = 1.0
    @stage.removeChild(@bmp) if @bmp
    @bmp = new createjs.Bitmap(img)
    @bmp.regX = img.width / 2
    @bmp.regY = img.height / 2
    @bmp.scaleX = @baseScale
    @bmp.scaleY = @baseScale
    @bmp.cache(0, 0, img.width, img.height)
    @stage.addChild(@bmp)
    @setValues(@values)

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

  clearEditor: ->
    @stage.removeChild(@bmp) if @stage and @bmp
    @bmp = null
    @img = null
    @values = {}
    @stage.update() if @stage

  setValues: (values) ->
    values ?= {}

    @values = values
    return unless @bmp && @canvas
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


Morandi.Engines = [
  Morandi.Rotation,
  Morandi.Straighten,
  #Morandi.Ratio,
  Morandi.Crop,
  Morandi.Colour,
  Morandi.SimpleColourFX,
  Morandi.Border
]
