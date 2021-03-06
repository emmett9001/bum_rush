package {
    import org.flixel.*;

    import flash.ui.GameInputControl;
    import flash.ui.GameInputDevice;

    public class MapPickerState extends GameState {
        [Embed(source="/../assets/fonts/Pixel_Berry_08_84_Ltd.Edition.TTF", fontFamily="Pixel_Berry_08_84_Ltd.Edition", embedAsCFF="false")] public var GameFont:String;
        [Embed(source = "../assets/audio/bumrush_select_loop.mp3")] private var SndBGMLoop:Class;
        [Embed(source="/../assets/images/worlds/maps/map_3_thumb.png")] private var ImgMapThumb3:Class;
        [Embed(source="/../assets/images/worlds/maps/map_4_thumb.png")] private var ImgMapThumb4:Class;
        [Embed(source="/../assets/images/worlds/maps/map_5_thumb.png")] private var ImgMapThumb5:Class;
        [Embed(source="/../assets/images/worlds/maps/map_6_thumb.png")] private var ImgMapThumb6:Class;
        [Embed(source="/../assets/images/worlds/maps/map_7_thumb.png")] private var ImgMapThumb7:Class;
        [Embed(source="/../assets/images/worlds/maps/map_8_thumb.png")] private var ImgMapThumb8:Class;
        [Embed(source="/../assets/images/worlds/maps/map_9_thumb.png")] private var ImgMapThumb9:Class;
        [Embed(source="/../assets/images/worlds/maps/map_10_thumb.png")] private var ImgMapThumb10:Class;
        [Embed(source="/../assets/images/worlds/maps/map_11_thumb.png")] private var ImgMapThumb11:Class;

        private var _maps:Array;
        private var _picker:FlxSprite;
        private var _cur_map:Number;
        private var _picker_lock:Boolean = false;
        private var _basic_label:FlxText;
        private var _small_label:FlxText;
        private var _advanced_label:FlxText;
        private var highlight_dim:DHPoint;
        private var row_count:Number;
        private var confirmLockTimeout:Number = 2;
        private var i:Number;
        private var bg:FlxExtSprite;

        override public function create():void {
            super.create();

            var thumb_dim:DHPoint = new DHPoint(300, 169);
            var rowSpacing:Number = PlayersController.getInstance().playersRegistered <= 4 ? .3 : .4;
            var rowY:Number = PlayersController.getInstance().playersRegistered <= 4 ?
                ScreenManager.getInstance().screenHeight * .15 :
                ScreenManager.getInstance().screenHeight * .2;
            this.highlight_dim = new DHPoint(9, 9);
            this.row_count = 3;

            ScreenManager.getInstance();
            var pathPrefix:String = "../assets/images/ui/";
            this.bg = ScreenManager.getInstance().loadSingleTileBG(pathPrefix + "mappicker_bg.png");

            this._maps = new Array();
            this._cur_map = 0;

            var t:FlxText;
            t = new FlxText(0, 20, ScreenManager.getInstance().screenWidth,
                            "Where do you want to go?");
            t.setFormat("Pixel_Berry_08_84_Ltd.Edition",20,0xffffffff);
            t.alignment = "center";
            add(t);

            this._picker = new FlxSprite(0, 0);
            this._picker.makeGraphic(thumb_dim.x + this.highlight_dim.x * 2,
                                     thumb_dim.y + this.highlight_dim.y * 2,
                                     0xffffffff);
            add(this._picker);

            var colSpacing:Number = 100;
            var thumb_:FlxSprite;

            if(PlayersController.getInstance().playersRegistered <= 4) {
                this.row_count = 3;

                _small_label = new FlxText(
                    0, rowY - 42,
                    ScreenManager.getInstance().screenWidth, "Small Maps (2-4 players)");
                _small_label.setFormat("Pixel_Berry_08_84_Ltd.Edition", 16, 0xffffffff);
                _small_label.alignment = "center";
                add(_small_label);

                thumb_ = new FlxSprite(
                    ScreenManager.getInstance().screenWidth * .5 - thumb_dim.x / 2 - colSpacing - thumb_dim.x,
                    rowY
                );
                thumb_.loadGraphic(ImgMapThumb9, false, false, thumb_dim.x, thumb_dim.y);
                add(thumb_);
                this._maps.push(thumb_);

                thumb_ = new FlxSprite(
                    ScreenManager.getInstance().screenWidth * .5 - thumb_dim.x / 2,
                    rowY
                );
                thumb_.loadGraphic(ImgMapThumb10, false, false, thumb_dim.x, thumb_dim.y);
                add(thumb_);
                this._maps.push(thumb_);

                thumb_ = new FlxSprite(
                    ScreenManager.getInstance().screenWidth * .5 + thumb_dim.x / 2 + colSpacing,
                    rowY
                );
                thumb_.loadGraphic(ImgMapThumb11, false, false, thumb_dim.x, thumb_dim.y);
                add(thumb_);
                this._maps.push(thumb_);

                rowY += ScreenManager.getInstance().screenHeight * rowSpacing;
            }

            _basic_label = new FlxText(
                0, rowY - 42,
                ScreenManager.getInstance().screenWidth, "Basic Maps (5+ players)");
            _basic_label.setFormat("Pixel_Berry_08_84_Ltd.Edition",16,0xffffffff);
            _basic_label.alignment = "center";
            add(_basic_label);

            thumb_ = new FlxSprite(
                ScreenManager.getInstance().screenWidth * .5 - thumb_dim.x / 2 - colSpacing - thumb_dim.x,
                rowY
            );
            thumb_.loadGraphic(ImgMapThumb6, false, false, thumb_dim.x, thumb_dim.y);
            add(thumb_);
            this._maps.push(thumb_);

            thumb_ = new FlxSprite(
                ScreenManager.getInstance().screenWidth * .5 - thumb_dim.x / 2,
                rowY
            );
            thumb_.loadGraphic(ImgMapThumb7, false, false, thumb_dim.x, thumb_dim.y);
            add(thumb_);
            this._maps.push(thumb_);

            thumb_ = new FlxSprite(
                ScreenManager.getInstance().screenWidth * .5 + thumb_dim.x / 2 + colSpacing,
                rowY
            );
            thumb_.loadGraphic(ImgMapThumb8, false, false, thumb_dim.x, thumb_dim.y);
            add(thumb_);
            this._maps.push(thumb_);

            rowY += ScreenManager.getInstance().screenHeight * rowSpacing;

            _advanced_label = new FlxText(
                0, rowY - 42,
                ScreenManager.getInstance().screenWidth, "Advanced Maps (5+ players)");
            _advanced_label.setFormat("Pixel_Berry_08_84_Ltd.Edition",16,0xffffffff);
            _advanced_label.alignment = "center";
            add(_advanced_label);

            thumb_ = new FlxSprite(
                ScreenManager.getInstance().screenWidth * .5 - thumb_dim.x / 2 - colSpacing - thumb_dim.x,
                rowY
            );
            thumb_.loadGraphic(ImgMapThumb3, false, false, thumb_dim.x, thumb_dim.y);
            add(thumb_);
            this._maps.push(thumb_);

            thumb_ = new FlxSprite(
                ScreenManager.getInstance().screenWidth * .5 - thumb_dim.x / 2,
                rowY
            );
            thumb_.loadGraphic(ImgMapThumb4, false, false, thumb_dim.x, thumb_dim.y);
            add(thumb_);
            this._maps.push(thumb_);

            thumb_ = new FlxSprite(
                ScreenManager.getInstance().screenWidth * .5 + thumb_dim.x / 2 + colSpacing,
                rowY
            );
            thumb_.loadGraphic(ImgMapThumb5, false, false, thumb_dim.x, thumb_dim.y);
            add(thumb_);
            this._maps.push(thumb_);

            this.addQuitElements();

            if (FlxG.music != null) {
                FlxG.music.stop();
            }
            FlxG.playMusic(SndBGMLoop, 1);
        }

        override public function controllerChanged(control:Object,
                                                   mapping:Object):void
        {
            super.controllerChanged(control, mapping);
            if (control['id'] == mapping["a"]["button"] && control['value'] == mapping["a"]["value_on"]) {
                this.startRace();
            }

            if(control['id'] == mapping["up"]["button"] && control['value'] == mapping["up"]["value_on"]) {
                this._cur_map += this.row_count;
            } else if (control['id'] == mapping["down"]["button"] && control['value'] == mapping["down"]["value_on"]) {
                this._cur_map -= this.row_count;
            } else if (control['id'] == mapping["right"]["button"] && control['value'] == mapping["right"]["value_on"]) {
                this._cur_map += 1;
            } else if (control['id'] == mapping["left"]["button"] && control['value'] == mapping["left"]["value_on"]) {
                this._cur_map -= 1;
            }
        }

        public function startRace():void {
            if (this.timeAlive > this.confirmLockTimeout * 1000) {
                // the top row of maps is actually last in the config arrays
                var idx:Number = this._cur_map;
                if (PlayersController.getInstance().playersRegistered <= 4) {
                    if (idx >= 3) {
                        idx -= 3;
                    } else {
                        idx += 6;
                    }
                }
                FlxG.switchState(new InstructionState(idx));
            }
        }

        override public function update():void {
            super.update();

            if(!this._picker_lock) {
                if(FlxG.keys.justPressed("DOWN")) {
                    this._picker_lock = true;
                    this._cur_map -= row_count;
                }
                if(FlxG.keys.justPressed("UP")) {
                    this._picker_lock = true;
                    this._cur_map += row_count;
                }
                if(FlxG.keys.justPressed("LEFT")) {
                    this._picker_lock = true;
                    this._cur_map -= 1;
                }
                if(FlxG.keys.justPressed("RIGHT")) {
                    this._picker_lock = true;
                    this._cur_map += 1;
                }
                if(FlxG.keys.justPressed("SPACE")) {
                    this.startRace();
                }
            } else {
                if(FlxG.keys.justReleased("DOWN") ||
                   FlxG.keys.justReleased("UP") ||
                   FlxG.keys.justReleased("RIGHT") ||
                   FlxG.keys.justReleased("LEFT")
                ) {
                    this._picker_lock = false;
                }
            }


            if(this._cur_map >= this._maps.length) {
                this._cur_map = this._cur_map % 3;
            } else if(this._cur_map < 0) {
                this._cur_map = this._maps.length + this._cur_map;
            }
            this._cur_map = Math.max(0, Math.min(this._cur_map, this._maps.length - 1))
            this._picker.x = this._maps[this._cur_map].x - this.highlight_dim.x;
            this._picker.y = this._maps[this._cur_map].y - this.highlight_dim.y;
        }
    }
}
