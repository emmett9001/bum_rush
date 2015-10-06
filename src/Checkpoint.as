package {
    import org.flixel.*;

    public class Checkpoint extends GameObject{
        [Embed(source="/../assets/images/worlds/BeerStore_1.png")] private var BoozeSprite:Class;
        [Embed(source="/../assets/images/worlds/Home_1.png")] private var HomeSprite:Class;
        [Embed(source="/../assets/images/worlds/MovieTheater_1.png")] private var MoviesSprite:Class;
        [Embed(source="/../assets/images/worlds/donkersDugout_3.png")] private var ParkSprite:Class;
        [Embed(source="/../assets/images/worlds/Beach.png")] private var BeachSprite:Class;
        [Embed(source="/../assets/images/worlds/BigFranks_21.png")] private var DinnerSprite:Class;
        [Embed(source="/../assets/images/worlds/NightClub_1.png")] private var ClubSprite:Class;

        [Embed(source="/../assets/images/worlds/street_overlay_1.png")] private var ImgStreetMarker:Class;
        [Embed(source="/../assets/images/worlds/street_icon_beer.png")] private var ImgStreetMarkerBeer:Class;
        [Embed(source="/../assets/images/worlds/street_icon_cocktail.png")] private var ImgStreetMarkerCocktail:Class;
        [Embed(source="/../assets/images/worlds/street_icon_film.png")] private var ImgStreetMarkerFilm:Class;
        [Embed(source="/../assets/images/worlds/street_icon_hotdog.png")] private var ImgStreetMarkerHotDog:Class;
        [Embed(source="/../assets/images/worlds/street_icon_tree.png")] private var ImgStreetMarkerTree:Class;
        [Embed(source="/../assets/images/worlds/street_overlay_heart_1.png")] private var ImgStreetMarkerHome:Class;

        [Embed(source="/../assets/audio/passenger.mp3")] private var CheckpointSFX:Class;

        private var dimensions:DHPoint;
        private var idx:Number, frameRate:Number = 12;
        public var checkpoint_sprite:GameObject;
        public var checkpoint_marker:GameObject;
        private var _cp_type:String;

        public static const BOOZE:String = "booze spot";
        public static const HOME:String = "start at home";
        public static const MOVIES:String = "movie theatre";
        public static const PARK:String = "picnicin";
        public static const BEACH:String = "swimmin";
        public static const DINNER:String = "chowin down";
        public static const CLUB:String = "clubbin bae";

        private var checkpointSound:FlxSound;
        private var completionIndicators:Object;

        public function Checkpoint(pos:DHPoint, dim:DHPoint, type:String=null) {
            super(pos);
            this.dimensions = dim;
            if(type != null) {
                this.checkpoint_sprite = new GameObject(pos);
            }

            this.checkpointSound = new FlxSound();
            this.checkpointSound.loadEmbedded(CheckpointSFX,false);
            this.checkpointSound.volume = 1;

            this.completionIndicators = {};
            var playerConfigs:Object = PlayersController.getInstance().playerConfigs;
            var indicator:FlxText, playerConfig:Object;
            for (var kid:Object in playerConfigs) {
                playerConfig = playerConfigs[kid];
                indicator = new FlxText(0, 0, 100, playerConfig['index'] + "");
                indicator.setFormat("Pixel_Berry_08_84_Ltd.Edition", 12, playerConfig['tint'], "left");
                this.completionIndicators[kid] = indicator;
            }

            this._cp_type = type;

            this.loadGraphic(ImgStreetMarker, false, false, 80, 40);
            this.checkpoint_marker = new GameObject(new DHPoint(-100, -100));

            switch (type) {
                case null:
                break;
                case Checkpoint.BOOZE:
                    this.checkpoint_sprite.loadGraphic(this.BoozeSprite, false, false, 128, 128);
                    this.checkpoint_marker.loadGraphic(this.ImgStreetMarkerBeer, false, false, 10, 18);
                break;
                case Checkpoint.HOME:
                    this.checkpoint_sprite.loadGraphic(this.HomeSprite, false, false, 128, 128);
                    this.checkpoint_marker.loadGraphic(this.ImgStreetMarkerHome, false, false, 12, 10);
                break;
                case Checkpoint.MOVIES:
                    this.checkpoint_sprite.loadGraphic(this.MoviesSprite, false, false, 128, 128);
                    this.checkpoint_marker.loadGraphic(this.ImgStreetMarkerFilm, false, false, 29, 14);
                break;
                case Checkpoint.PARK:
                    this.checkpoint_sprite.loadGraphic(this.ParkSprite, false, false, 384 / 3, 128);
                    this.checkpoint_sprite.addAnimation("anim", [0,1,2], 7, true);
                    this.checkpoint_sprite.play("anim");
                    this.checkpoint_marker.loadGraphic(this.ImgStreetMarkerTree, false, false, 12, 14);
                break;
                case Checkpoint.BEACH:
                    this.checkpoint_sprite.loadGraphic(this.BeachSprite, false, false, 128, 128);
                break;
                case Checkpoint.DINNER:
                    this.checkpoint_sprite.loadGraphic(this.DinnerSprite, false, false, 146, 85);
                    this.checkpoint_sprite.addAnimation("anim", [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,29,20,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0], this.frameRate, true);
                    this.checkpoint_sprite.play("anim");
                    this.checkpoint_marker.loadGraphic(this.ImgStreetMarkerHotDog, false, false, 26, 9);
                break;
                case Checkpoint.CLUB:
                    this.checkpoint_sprite.loadGraphic(this.ClubSprite, false, false, 128, 128);
                    this.checkpoint_marker.loadGraphic(this.ImgStreetMarkerCocktail, false, false, 11, 15);
                break;
            }
        }

        public function get index():Number {
            return this.idx;
        }

        public function set index(n:Number):void {
            this.idx = n;
        }

        public function get cp_type():String {
            return this._cp_type;
        }

        public function setImgPos(p:DHPoint):void {
            if(this.checkpoint_sprite != null) {
                this.checkpoint_sprite.setPos(p);
            }
        }

        override public function setPos(pos:DHPoint):void {
            super.setPos(pos);
            var cur:FlxText;
            var row:Number = 0, col:Number = 0;
            for (var kid:Object in this.completionIndicators) {
                cur = this.completionIndicators[kid];
                cur.x = this.x + (9 * col);
                cur.y = this.y + (13 * row);
                if (row < 1) {
                    row++;
                } else {
                    row = 0;
                }
                if (col < 4) {
                    col++;
                } else {
                    col = 0;
                }
            }
        }

        public function setMarkerRotation(r:Number):void {
            this.angle = r;
        }

        public function setMarkerIconPos():void {
            this.checkpoint_marker.setPos(new DHPoint(this.pos.x + (this.width/2 - this.checkpoint_marker.width/2), this.pos.y + (this.height/2 - this.checkpoint_marker.height/2)));
        }

        public function playSfx():void {
            this.checkpointSound.play();
        }

        public function stopSfx():void {
            this.checkpointSound.stop();
        }

        public function markComplete(kid:Number):void {
            this.completionIndicators[kid].visible = false;
        }

        override public function addVisibleObjects():void {
            FlxG.state.add(this);
            FlxG.state.add(this.checkpoint_sprite);
            FlxG.state.add(this.checkpoint_marker);
            for (var kid:Object in this.completionIndicators) {
                FlxG.state.add(this.completionIndicators[kid]);
            }
        }
    }
}
