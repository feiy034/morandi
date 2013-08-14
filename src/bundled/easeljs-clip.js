/*!
 * EaselJS clip plugin v0.01
 * https://github.com/CindyLinz/EaselJS-clip
 *
 * Copyright 2012, Cindy Wang (CindyLinz)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 *
 * Date: 2012.4.25
 */
(function(createjs){
    var i;
    var classes_name = ['Container', 'BitmapAnimation', 'DOMElement', 'Text', 'Bitmap', 'Shape', 'Stage'];
    for(i=0; i<classes_name.length; ++i)
        if( createjs[classes_name[i]] && createjs[classes_name[i]].prototype && createjs[classes_name[i]].prototype.draw )
            (function(ori_draw){
                createjs[classes_name[i]].prototype.draw = function(ctx){
                    if( this.clip && this.clip.draw ){
                        ctx.save();
                        this.clip.draw(ctx);
                        ctx.clip();
                        ori_draw.apply(this, arguments);
                        ctx.restore();
                    }
                    else{
                        ori_draw.apply(this, arguments);
                    }
                };
            })(createjs[classes_name[i]].prototype.draw);
})(window.createjs);

