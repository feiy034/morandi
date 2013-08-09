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
      if (this.bmp) this.stage.removeChild(this.bmp);
      this.bmp = new createjs.Bitmap(img);
      this.bmp.regX = img.width / 2;
      this.bmp.regY = img.height / 2;
      this.bmp.scaleX = this.bmp.scaleY = this.baseScale;
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
      cm = new createjs.ColorMatrix();
      cm.adjustColor(values.brightness, values.contrast, values.saturation, values.hue);
      this.colorFilter = new createjs.ColorMatrixFilter(cm);
      this.blurFilter = new createjs.BoxBlurFilter(values.blurX, values.blurY, 2);
      rotationValueRad = Math.abs(values.rotation * Math.PI / 180.0);
      scale = this.baseScale * this.bmp.image.height / ((this.bmp.image.width * Math.sin(rotationValueRad)) + (this.bmp.image.height * Math.cos(rotationValueRad)));
      this.bmp.scaleX = scale;
      this.bmp.scaleY = scale;
      this.bmp.rotation = values.rotation;
      this.bmp.x = canvas.width / 2;
      this.bmp.y = canvas.height / 2;
      ratio = 6.0 / 4.0;
      rh = this.bmp.image.height / ((ratio * Math.sin(rotationValueRad)) + Math.cos(rotationValueRad));
      rh = rh * scale / 2;
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
