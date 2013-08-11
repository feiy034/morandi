(function() {
  var root,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  root.Morandi = {};

  root.Morandi.EditMode = (function() {

    function EditMode() {}

    EditMode.prototype.addTo = function(editor) {
      return this.editor = editor;
    };

    EditMode.prototype.removeFrom = function(editor) {};

    return EditMode;

  })();

  root.Morandi.Straighten = (function(_super) {

    __extends(Straighten, _super);

    function Straighten() {
      Straighten.__super__.constructor.apply(this, arguments);
    }

    Straighten.prototype.addTo = function(editor) {
      Straighten.__super__.addTo.apply(this, arguments);
      this.editor.shape = new createjs.Shape();
      return this.editor.stage.addChild(this.editor.shape);
    };

    Straighten.prototype.removeFrom = function(editor) {
      this.editor.stage.removeChild(this.editor.shape);
      return Straighten.__super__.removeFrom.apply(this, arguments);
    };

    Straighten.prototype.setValues = function(values) {
      var h, ratio, rh, rotationValueRad, rw, scale, w, x, y;
      if (values == null) values = {};
      if (values.rotation == null) values.rotation = 0;
      rotationValueRad = Math.abs(values.rotation * Math.PI / 180.0);
      scale = this.editor.baseScale * this.editor.bmp.image.height / ((this.editor.bmp.image.width * Math.sin(rotationValueRad)) + (this.editor.bmp.image.height * Math.cos(rotationValueRad)));
      this.editor.bmp.scaleX = scale;
      this.editor.bmp.scaleY = scale;
      this.editor.bmp.rotation = values.rotation;
      ratio = 6.0 / 4.0;
      rh = this.editor.bmp.image.height / ((ratio * Math.sin(rotationValueRad)) + Math.cos(rotationValueRad));
      rh = rh * scale / this.editor.baseScale;
      rw = rh * ratio;
      x = (this.editor.canvas.width / 2) - (this.editor.baseScale * rw / 2);
      y = (this.editor.canvas.height / 2) - (this.editor.baseScale * rh / 2);
      w = rw * this.editor.baseScale;
      h = rh * this.editor.baseScale;
      return this.editor.shape.graphics = new createjs.Graphics().beginStroke('#00ff00').rect(x, y, w, h);
    };

    Straighten.prototype.update = function() {};

    return Straighten;

  })(root.Morandi.EditMode);

  root.Morandi.Colour = (function(_super) {

    __extends(Colour, _super);

    function Colour() {
      Colour.__super__.constructor.apply(this, arguments);
    }

    Colour.prototype.setValues = function(values) {
      var cm;
      if (values == null) values = {};
      if (values.brightness == null) values.brightness = 0;
      if (values.contrast == null) values.contrast = 0;
      if (values.saturation == null) values.saturation = 0;
      if (values.hue == null) values.hue = 0;
      if (values.redChannel == null) values.redChannel = 255;
      if (values.greenChannel == null) values.greenChannel = 255;
      if (values.blueChannel == null) values.blueChannel = 255;
      if (values.blurX == null) values.blurX = 0;
      if (values.blurY == null) values.blurY = 0;
      cm = new createjs.ColorMatrix();
      cm.adjustColor(values.brightness, values.contrast, values.saturation, values.hue);
      this.colorFilter = new createjs.ColorMatrixFilter(cm);
      this.blurFilter = new createjs.BoxBlurFilter(values.blurX, values.blurY, 2);
      this.redChannelFilter = new createjs.ColorFilter(values.redChannel / 255, 1, 1, 1);
      this.greenChannelFilter = new createjs.ColorFilter(1, values.greenChannel / 255, 1, 1);
      return this.blueChannelFilter = new createjs.ColorFilter(1, 1, values.blueChannel / 255, 1);
    };

    Colour.prototype.update = function() {
      var _ref, _ref2, _ref3, _ref4;
      if (!this.editor.bmp) return;
      if ((_ref = this.editor) != null) {
        if ((_ref2 = _ref.bmp) != null) {
          _ref2.filters = [this.colorFilter, this.blurFilter, this.redChannelFilter, this.greenChannelFilter, this.blueChannelFilter];
        }
      }
      return (_ref3 = this.editor) != null ? (_ref4 = _ref3.bmp) != null ? _ref4.updateCache() : void 0 : void 0;
    };

    Colour.prototype.addTo = function(editor) {
      this.editor = editor;
      return Colour.__super__.addTo.apply(this, arguments);
    };

    Colour.prototype.removeFrom = function(editor) {
      var _ref, _ref2, _ref3, _ref4;
      if ((_ref = this.editor) != null) {
        if ((_ref2 = _ref.bmp) != null) _ref2.filters = [];
      }
      if ((_ref3 = this.editor) != null) {
        if ((_ref4 = _ref3.bmp) != null) _ref4.updateCache();
      }
      return Colour.__super__.removeFrom.apply(this, arguments);
    };

    return Colour;

  })(root.Morandi.EditMode);

  root.MorandiEditor = (function() {

    function MorandiEditor(canvas) {
      this.baseScale = 2;
      this.stage = new createjs.Stage(canvas);
      this.canvas = canvas;
      this.setEngine(new root.Morandi.Colour());
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
      $(this.canvas).trigger('loaded', this.bmp);
      return this.setValues();
    };

    MorandiEditor.prototype.loadImage = function(src) {
      var img,
        _this = this;
      this.url = src;
      this.settings = {};
      img = new Image();
      img.onload = (function() {
        return _this.loadedImage(img);
      });
      return img.src = src;
    };

    MorandiEditor.prototype.setEngine = function(engine) {
      if (this.engine) this.engine.removeFrom(this);
      this.engine = engine;
      return this.engine.addTo(this);
    };

    MorandiEditor.prototype.setValues = function(values) {
      if (values == null) values = {};
      this.bmp.x = this.canvas.width / 2;
      this.bmp.y = this.canvas.height / 2;
      this.bmp.scaleX = this.baseScale;
      this.bmp.scaleY = this.baseScale;
      this.bmp.rotation = 0;
      this.engine.setValues(values);
      return this.update();
    };

    MorandiEditor.prototype.update = function() {
      this.engine.update();
      return this.stage.update();
    };

    return MorandiEditor;

  })();

}).call(this);
