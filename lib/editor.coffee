root = exports ? this
class root.MorandiEditor
  constructor: (canvas) ->
    @baseScale = 2
    @stage = new createjs.Stage(canvas)
    @canvas = canvas
    @shape = new createjs.Shape()
    @stage.addChild(@shape)

  loadedImage: (img) ->
    @stage.removeChild(@bmp) if @bmp

    @bmp = new createjs.Bitmap(img)
    @bmp.regX = img.width / 2
    @bmp.regY = img.height / 2
    @bmp.scaleX = @bmp.scaleY = @baseScale
    @bmp.cache(0, 0, img.width, img.height)
    @stage.addChild(@bmp)
    @stage.setChildIndex(@bmp, 0)

    $(@canvas).trigger('loaded', @bmp)

  loadImage: (src) ->
    img = new Image()
    img.onload = (=> @loadedImage(img))
    img.src = src

  apply: (values) ->
    cm = new createjs.ColorMatrix()
    cm.adjustColor(values.brightness, values.contrast, values.saturation, values.hue)

    @colorFilter = new createjs.ColorMatrixFilter(cm)
    @blurFilter = new createjs.BoxBlurFilter(values.blurX, values.blurY, 2)
    #redChannelFilter = new createjs.ColorFilter(redChannelvalue/255,1,1,1)
    #greenChannelFilter = new createjs.ColorFilter(1,greenChannelValue/255,1,1)
    #blueChannelFilter = new createjs.ColorFilter(1,1,blueChannelValue/255,1)

    rotationValueRad = Math.abs(values.rotation * Math.PI / 180.0)
    scale = @baseScale * @bmp.image.height / ((@bmp.image.width * Math.sin(rotationValueRad)) + (@bmp.image.height * Math.cos(rotationValueRad)))

    @bmp.scaleX = scale
    @bmp.scaleY = scale
    @bmp.rotation = values.rotation
    @bmp.x = canvas.width / 2
    @bmp.y = canvas.height / 2

    ratio = 6.0/4.0
    rh = (@bmp.image.height) / ((ratio * Math.sin(rotationValueRad)) + Math.cos(rotationValueRad))

    rh = rh * scale / 2 # Scale down to fit scaled down rect
    rw = rh * ratio

    x = (@canvas.width / 2) - (@baseScale * rw / 2)
    y = (@canvas.height / 2) - (@baseScale * rh / 2)
    w = rw * @baseScale
    h = rh * @baseScale
    
    @shape.graphics = new createjs.Graphics().beginStroke('#00ff00').rect(x, y, w, h)
    @update()
    
  update: ->
    return unless @bmp
    @bmp.filters = [@colorFilter, @blurFilter] #, redChannelFilter, greenChannelFilter, blueChannelFilter]
    @bmp.updateCache()
    @stage.update()
