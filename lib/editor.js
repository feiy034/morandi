(function() {
  var root;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  root.MorandiEditor = (function() {

    function MorandiEditor(canvas) {
      this.baseScale = 2;
      this.stage = new createjs.Stage(canvas);
      this.canvas = canvas;
      this.shape = new createjs.Shape();
      this.stage.addChild(this.shape);
    }

    MorandiEditor.prototype.loadedImage = function(img) {
      var scale1, scale2;
      if (this.bmp) this.stage.removeChild(this.bmp);
      scale1 = this.canvas.width / img.width;
      scale2 = this.canvas.height / img.height;
      if (scale1 < scale2) {
        this.baseScale = scale1;
      } else {
        this.baseScale = scale2;
      }
      this.bmp = new createjs.Bitmap(img);
      this.bmp.regX = img.width / 2;
      this.bmp.regY = img.height / 2;
      this.bmp.scaleX = this.baseScale;
      this.bmp.scaleY = this.baseScale;
      this.bmp.cache(0, 0, img.width, img.height);
      this.stage.addChild(this.bmp);
      this.stage.setChildIndex(this.bmp, 0);
      return $(this.canvas).trigger('loaded', this.bmp);
    };

    MorandiEditor.prototype.loadImage = function(src) {
      var img,
        _this = this;
      img = new Image();
      img.onload = (function() {
        return _this.loadedImage(img);
      });
      return img.src = src;
    };

    MorandiEditor.prototype.apply = function(values) {
      var cm, h, ratio, rh, rotationValueRad, rw, scale, w, x, y;
      if (values == null) values = {};
      if (values.rotation == null) values.rotation = 0;
      if (values.brightness == null) values.brightness = 0;
      if (values.contrast == null) values.contrast = 0;
      if (values.saturation == null) values.saturation = 0;
      if (values.hue == null) values.hue = 0;
      if (values.blurX == null) values.blurX = 0;
      if (values.blurY == null) values.blurY = 0;
      cm = new createjs.ColorMatrix();
      cm.adjustColor(values.brightness, values.contrast, values.saturation, values.hue);
      this.colorFilter = new createjs.ColorMatrixFilter(cm);
      this.blurFilter = new createjs.BoxBlurFilter(values.blurX, values.blurY, 2);
      rotationValueRad = Math.abs(values.rotation * Math.PI / 180.0);
      scale = this.baseScale * this.bmp.image.height / ((this.bmp.image.width * Math.sin(rotationValueRad)) + (this.bmp.image.height * Math.cos(rotationValueRad)));
      this.bmp.scaleX = scale;
      this.bmp.scaleY = scale;
      this.bmp.rotation = values.rotation;
      this.bmp.x = this.canvas.width / 2;
      this.bmp.y = this.canvas.height / 2;
      ratio = 6.0 / 4.0;
      rh = this.bmp.image.height / ((ratio * Math.sin(rotationValueRad)) + Math.cos(rotationValueRad));
      rh = rh * scale / this.baseScale;
      rw = rh * ratio;
      x = (this.canvas.width / 2) - (this.baseScale * rw / 2);
      y = (this.canvas.height / 2) - (this.baseScale * rh / 2);
      w = rw * this.baseScale;
      h = rh * this.baseScale;
      this.shape.graphics = new createjs.Graphics().beginStroke('#00ff00').rect(x, y, w, h);
      return this.update();
    };

    MorandiEditor.prototype.update = function() {
      if (!this.bmp) return;
      this.bmp.filters = [this.colorFilter, this.blurFilter];
      this.bmp.updateCache();
      return this.stage.update();
    };

    return MorandiEditor;

  })();

}).call(this);
