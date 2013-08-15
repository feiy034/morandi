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


class root.Morandi.EditFilter
  defaults: {}

  constructor: (editor) ->
    @editor = editor

  defaultValues: (values) ->
    values ?= {}
    values[key] ?= val for key, val of @defaults
    values
  addTo: (editor) ->
    @editor = editor
  removeFrom: (editor) ->
  className: ->
    @constructor.name
  applyFilter: (ctx, x, y, width, height, targetCtx=ctx, targetX=x, targetY=y) ->







"""
Morandi.Border

Keys: border-style, background-style.

Renders border on image
"""

class root.Morandi.Border extends root.Morandi.EditFilter
  defaults:
    'border-style': ''
    'background-style': 'white'

  addTo: (editor) ->
    editor.border = new createjs.Shape()
    editor.stage.addChild(editor.border)
    super

  removeFrom: (editor) ->
    @editor.stage.removeChild(@editor.border)
    delete @editor.border
    super

  applyFilter: (ctx, x, y, width, height, targetCtx=ctx, targetX=x, targetY=y) ->
    values = @defaultValues(@editor.values)

    dup = @editor.copyCanvas(@editor.bmp.cacheCanvas)
    @editor.bmp.cacheCanvas.width = @editor.bmp.cacheCanvas.width
    #p [@angle, rotationValueRad, rh, scale, pixbuf.height]
    ctx.save()


    switch values['background-style']
      when 'white'
        fill = createjs.Graphics.getRGB(255, 255, 255)
      when 'black'
        fill = createjs.Graphics.getRGB(0, 0, 0)
      when 'dominant'
        colorThief = new ColorThief()
        col = colorThief.getColor(dup)
        fill = createjs.Graphics.getRGB(col[0], col[1], col[2])

    ctx.rect(0,0,width,height)
    ctx.fillStyle= fill
    ctx.fill()


    bmp = new createjs.Bitmap(dup)

    borderWidth = 20
    if values['border-style'] is 'square'
      clip = new createjs.Graphics()
      clip.rect(borderWidth,borderWidth,dup.width-(2*borderWidth), dup.height-(2*borderWidth))
      bmp.clip = clip
    else if values['border-style'] is 'retro'
      clip = new createjs.Graphics()
      Morandi.roundedRectangle(clip, borderWidth, borderWidth, dup.width-(borderWidth), dup.height-(borderWidth), 30)
      bmp.clip = clip
    bmp.draw(ctx, true)

  setValues: (values) ->
    values = @defaultValues(values)

    scale = @editor.baseScale * 0.85
    @editor.bmp.scaleX = scale
    @editor.bmp.scaleY = scale
    @editor.bmp.rotation = 0 # values.straighten

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

    switch values['background-style']
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

class root.Morandi.Rotation extends root.Morandi.EditFilter
  @applyTo: (editor, image) ->
    image

class root.Morandi.Crop extends root.Morandi.EditFilter
  defaults:
    zoom: 1.0
    xalign: 0.5
    yalign: 0.5

  addTo: (editor) ->
    super
    @editor.shape = new createjs.Shape()
    @editor.stage.addChild(@editor.shape)

  removeFrom: (editor) ->
    @editor.stage.removeChild(@editor.shape)
    super
  applyFilter: (ctx, x, y, width, height, targetCtx=ctx, targetX=x, targetY=y) ->
    values = @defaultValues(@editor.values)

    dup = @editor.copyCanvas(@editor.bmp.cacheCanvas)
    @editor.bmp.cacheCanvas.width = @editor.bmp.cacheCanvas.width
    ctx.save()
    ctx.translate(width/2,height/2)

    xdiff = (values.zoom - 1) * width
    ydiff = (values.zoom - 1) * height

    ctx.translate((values.xalign * xdiff * -1) - (width/2), (values.yalign * ydiff * -1) - (height/2))
    ctx.scale(values.zoom, values.zoom)

    ctx.drawImage(dup, 0, 0)

    ctx.restore()
  setValues: (values) ->
    values = @defaultValues(values)

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


class root.Morandi.Straighten extends root.Morandi.EditFilter
  defaults:
    straighten: 0
  addTo: (editor) ->
    super
    @editor.shape = new createjs.Shape()
    @editor.stage.addChild(@editor.shape)

  applyFilter: (ctx, x, y, width, height, targetCtx=ctx, targetX=x, targetY=y) ->
    values = @defaultValues(@editor.values)

    ratio = @editor.ratio ? Morandi.DEFAULT_RATIO
    rotationValueRad = values.straighten * (Math.PI/180)

    rh = (height) / ((ratio * Math.sin(Math.abs(rotationValueRad))) + Math.cos(Math.abs(rotationValueRad)))

    scale = Math.abs(height / rh)

    dup = @editor.copyCanvas(@editor.bmp.cacheCanvas)
    @editor.bmp.cacheCanvas.width = @editor.bmp.cacheCanvas.width
    #p [@angle, rotationValueRad, rh, scale, pixbuf.height]
    ctx.save()

    ctx.translate(width / 2.0, height / 2.0)
    ctx.rotate(rotationValueRad)
    ctx.scale(scale, scale)
    ctx.translate(width / -2.0, height / - 2.0)
    ctx.drawImage(dup, 0, 0)

    ctx.restore()


  removeFrom: (editor) ->
    @editor.stage.removeChild(@editor.shape)
    @editor.bmp.rotation = 0
    super

  setValues: (values) ->
    values = @defaultValues(values)
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

class root.Morandi.SimpleColourFX extends root.Morandi.EditFilter
  defaults:
    fx: 'colour'

  applyFilter: (ctx, x, y, width, height, targetCtx=ctx, targetX=x, targetY=y) ->
    @setValues(@editor.values)
    for filter in @filters
      filter.applyFilter(ctx, x, y, width, height, targetCtx, targetX, targetY)

  setValues: (values) ->
    values = @defaultValues(values)
    
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
    return unless @editor?.bmp
    @editor.bmp.filters = @filters ? []
    @editor.bmp.updateCache()

  addTo: (editor) ->
    @editor = editor
    super

  removeFrom: (editor) ->
    if @editor?.bmp
      @editor.bmp.filters = []
      @editor.bmp.updateCache()
    super

"""
class root.Morandi.Colour extends root.Morandi.EditFilter
  defaults:
    brightness: 0
    contrast: 0
    saturation: 0
    hue: 0
    redChannel: 255
    greenChannel: 255
    blueChannel: 255
    blurX: 0
    blurY: 0

  setValues: (values) ->
    values = @defaultValues(values)
    
    cm = new createjs.ColorMatrix()
    cm.adjustColor(values.brightness, values.contrast, values.saturation, values.hue)

    @colorFilter = new createjs.ColorMatrixFilter(cm)
    @blurFilter = new createjs.BoxBlurFilter(values.blurX, values.blurY, 2)
    @redChannelFilter = new createjs.ColorFilter(values.redChannel/255,1,1,1)
    @greenChannelFilter = new createjs.ColorFilter(1,values.greenChannel/255,1,1)
    @blueChannelFilter = new createjs.ColorFilter(1,1,values.blueChannel/255,1)

  update: ->
    return unless @editor.bmp
    #@editor?.bmp?.filters = [@colorFilter, @blurFilter, @redChannelFilter, @greenChannelFilter, @blueChannelFilter]
    #@editor?.bmp?.updateCache()

  addTo: (editor) ->
    @editor = editor
    super

  removeFrom: (editor) ->
    #@editor?.bmp?.filters = []
    #@editor?.bmp?.updateCache()
    super
"""

class root.MorandiEditor
  constructor: (canvas) ->
    @baseScale = 2
    @stage = new createjs.Stage(canvas)
    @canvas = canvas
    #@setEngine(new root.Morandi.Colour(@))

  scaledSource: (orig) ->
    @orig = orig
    scale1 = @canvas.width / @orig.width
    scale2 = @canvas.height / @orig.height

    scale = scale1
    scale = scale2 if scale2 < scale1

    cCopy        = document.createElement("canvas")
    cContext     = cCopy.getContext("2d")
    cCopy.width  = scale * @orig.width
    cCopy.height = scale * @orig.height

    cContext.drawImage(@orig, 0, 0, @orig.width, @orig.height, 0, 0, cCopy.width, cCopy.height)

    @source = cCopy
    @sourceScale = scale

    @baseScale = 1.0

    cCopy

  loadedImage: (original) ->
    @stage.removeChild(@bmp) if @bmp

    @realWidth = original.width
    @realHeight = original.height

    image = @scaledSource(original)

    @bmp = new createjs.Bitmap(image)
    @bmp.regX = image.width / 2
    @bmp.regY = image.height / 2
    @bmp.scaleX = @baseScale
    @bmp.scaleY = @baseScale
    @stage.addChild(@bmp)

    @setRatio(6/4)
    @bmp.filters = (new klass(@) for klass in Morandi.Engines)
    @bmp.cache(0, 0, @bmp.image.width, @bmp.image.height)
    $(@canvas).trigger('loaded', @bmp)

    @setValues(@values ? {})

  processImage: (image) ->
    for engineClass in Morandi.Engines
      image = engineClass.applyTo(@, image)
      #return if engineClass.name == @engine?.className()
    image

  copyCanvas: (canvas) ->
    newCanvas = document.createElement('canvas')
    newCanvas.width = canvas.width
    newCanvas.height = canvas.height
    ctx = newCanvas.getContext('2d')
    ctx.drawImage(canvas, 0,0)
    newCanvas

  setRatio: (ratio) ->
    @ratio = ratio
    return unless @source

    cratio = @canvas.width / @canvas.height
    iratio = @source.width / @source.height

    x = y = 0

    largest = Morandi.largestAspectRectangle(ratio, @source.width, @source.height)

    scale1 = @canvas.height / largest.height
    scale2 = @canvas.width / largest.width

    scale = scale1
    scale = scale2 if scale2 < scale1

    img = document.createElement("canvas")
    cr = img.getContext("2d")
    img.width = largest.width * scale
    img.height = largest.height * scale
    cr.drawImage(@source, largest.x, largest.y, largest.width, largest.height, 0, 0, img.width, img.height)
    @baseScale = 1.0
    @stage.removeChild(@bmp) if @bmp
    @bmp = new createjs.Bitmap(img)
    @bmp.regX = img.width / 2
    @bmp.regY = img.height / 2
    @bmp.scaleX = @baseScale
    @bmp.scaleY = @baseScale
    @bmp.filters = (new klass(@) for klass in Morandi.Engines)
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
    #@engine.removeFrom(@) if @engine
    #@engine = engine
    #@engine.addTo(@)

  clearEditor: ->
    @stage.removeChild(@bmp) if @stage and @bmp
    @bmp = null
    @img = null
    @values = {}
    @stage.update() if @stage

  setAngle: (angle) ->
    @values ?= {}
    @values.angle = angle
    @setValues(@values)

  setValues: (values) ->
    values ?= {}

    @values = values
    valuesJSON = SortedJSON.encode(@values)
    if @lastValues && valuesJSON != @lastValues
      $(@canvas).trigger('modified', JSON.parse(valuesJSON)) # unmodifiable

    return unless @bmp && @canvas
    # Check image is centered
    @bmp.x = @canvas.width / 2
    @bmp.y = @canvas.height / 2

    scale = @baseScale
    if @values.angle in [90,270]
      s = @canvas.height / @bmp.image.width
      s2 = @canvas.width / @bmp.image.height
      scale = s2 if s2 < scale
      scale = s if s < scale
      #console.log("Scale was: (base=#{ @baseScale }) #{scale} - cmp #{s} & #{s2}")
      #console.log("#{@bmp.image.width} : #{@canvas.height}")

      #console.log("Scale is: #{scale} - #{@bmp.image.width} : #{@canvas.height}")

    @bmp.scaleX = scale
    @bmp.scaleY = scale

      
    @bmp.rotation = @values.angle ? 0
    @bmp.updateCache()

    #@engine.setValues(values)
    @update()

  update: ->
    @engine.update() if @engine
    @stage.update()


Morandi.Engines = [
  Morandi.Rotation,
  Morandi.Straighten,
  #Morandi.Ratio,
  Morandi.Crop,
  Morandi.SimpleColourFX,
  Morandi.Border
]
