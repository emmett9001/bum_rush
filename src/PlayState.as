package {
    import org.flixel.*;
    import org.flixel.plugin.photonstorm.FlxCollision;

    import Box2D.Dynamics.*;
    import Box2D.Collision.*;
    import Box2D.Collision.Shapes.*;
    import Box2D.Common.Math.*;
    import Box2D.Dynamics.Joints.*;

    import flash.display.Sprite;

    public class PlayState extends GameState {
        [Embed(source="/../assets/intro.png")] private var InstructionSprite:Class;
        [Embed(source="/../assets/readysetgo.png")] private var StartSprite:Class;
        [Embed(source="/../assets/timeout.png")] private var TimeOutSprite:Class;

        private var m_physScale:Number = 30
        private var checkpoints:Array;
        private var instructions:GameObject, start_sprite:GameObject, time_out_sprite:GameObject;
        private var started_race:Boolean = false, shown_start_anim:Boolean = false, finished:Boolean = false;
        private var raceTimeAlive:Number, raceEndTimer:Number;
        private var collider:FlxExtSprite;
        private static const RACE_LENGTH:Number = 60;

        public var m_world:b2World;

        private var map_paths:Array = ["assets/map_2"];
        private var map_checkpoints:Array = [[Checkpoint.HOME, Checkpoint.BOOZE,  Checkpoint.MOVIES, Checkpoint.PARK, Checkpoint.BEACH, Checkpoint.DINNER]]
        private var map_checkpoints_positions:Array = [[new DHPoint(.4, .62), new DHPoint(.5, .62), new DHPoint(.7, .25), new DHPoint(.8, .63), new DHPoint(.1, .27), new DHPoint(.3, .45)]]
        private var active_map_index:Number;
        private var home_cp_index:Number;
        private var groundBody:b2Body;

        override public function create():void {
            super.create();

            //TODO pick a random map
            this.active_map_index = 0;

            this.collider = ScreenManager.getInstance().loadSingleTileBG(this.map_paths[this.active_map_index] + "_collider.png");
            ScreenManager.getInstance().loadSingleTileBG(this.map_paths[this.active_map_index] + ".png");
            this.gameActive = true;

            this.checkpoints = new Array();
            var checkpoint:Checkpoint;
            var i:Number = 0;
            for(i = 0; i < this.map_checkpoints[this.active_map_index].length; i++) {
                checkpoint = new Checkpoint(
                    new DHPoint(100, 100),
                    new DHPoint(20, 20),
                    this.map_checkpoints[this.active_map_index][i]
                );
                this.checkpoints.push(checkpoint);
                if(this.map_checkpoints[this.active_map_index][i] == Checkpoint.HOME) {
                    this.home_cp_index = i;
                }
            }

            var that:PlayState = this;
            FlxG.stage.addEventListener(GameState.EVENT_SINGLETILE_BG_LOADED,
                function(event:DHDataEvent):void {
                    that.setupWorld(event.userData['bg']);
                    PlayersController.getInstance().addRegisteredPlayers(
                        that.checkpoints.length, that.active_map_index,
                        that.m_world, that.groundBody);
                    var cur:Checkpoint;
                    for(var p:Number = 0; p < that.checkpoints.length; p++) {
                        var cp_pos:DHPoint = that.map_checkpoints_positions[that.active_map_index][p];
                        cur = that.checkpoints[p];
                        cur.setPos(new DHPoint(
                            event.userData['bg'].x + event.userData['bg'].width * (cp_pos.x + .05),
                            event.userData['bg'].y + event.userData['bg'].height * cp_pos.y
                        ));
                        cur.setImgPos(new DHPoint(
                            event.userData['bg'].x + event.userData['bg'].width * cp_pos.x,
                            event.userData['bg'].y + event.userData['bg'].height * cp_pos.y
                        ));
                        cur.index = p;
                    }

                    FlxG.stage.removeEventListener(
                        GameState.EVENT_SINGLETILE_BG_LOADED,
                        arguments.callee
                    );
                });

            for (i = 0; i < this.checkpoints.length; i++) {
                this.checkpoints[i].addVisibleObjects();
            }

            this.start_sprite = new GameObject(new DHPoint(0,0));
            this.start_sprite.loadGraphic(this.StartSprite, true, false, 1280, 720);
            this.start_sprite.addAnimation("play", [0,1,2], .5, false);
            this.start_sprite.visible = false;
            FlxG.state.add(this.start_sprite);

            this.time_out_sprite = new GameObject(new DHPoint(0,0));
            this.time_out_sprite.loadGraphic(this.TimeOutSprite, false, false, 1280, 720);
            FlxG.state.add(this.time_out_sprite);
            this.time_out_sprite.visible = false;

            this.instructions = new GameObject(new DHPoint(0,0));
            this.instructions.loadGraphic(this.InstructionSprite,true,false,1280,720);
            FlxG.state.add(this.instructions);

            this.startRaceTimer();
        }

        override public function update():void {
            super.update();

            if (this.m_world != null) {
                this.m_world.Step(1.0 / 30.0, 10, 10);
                m_world.DrawDebugData();
            }

            this.raceTimeAlive = this.curTime - this.raceBornTime;
            if(this.raceTimeAlive/1000 > 3) {
                if(!this.started_race) {
                    if(!this.shown_start_anim) {
                        this.instructions.visible = false;
                        this.start_sprite.visible = true;
                        this.start_sprite.play("play");
                        this.shown_start_anim = true;
                    }

                    if(this.start_sprite.finished) {
                        this.start_sprite.visible = false;
                        this.started_race = true;
                        var players_list:Array;
                        players_list = PlayersController.getInstance().getPlayerList();
                        for(var p:Number = 0; p < players_list.length; p++) {
                            players_list[p].driving = true;
                        }
                    }
                }
            }

            if(this.finished) {
                if(this.raceEndTimer <= this.raceTimeAlive/1000) {
                    FlxG.switchState(new EndState());
                }
            }

            var colliders:Array = PlayersController.getInstance().getPlayerColliders(),
                checkpoint:Checkpoint, curPlayer:Player, curCollider:GameObject,
                k:int, collisionData:Array;
            for (var i:int = 0; i < colliders.length; i++) {
                curCollider = colliders[i];
                curPlayer = curCollider.parent as Player;
                curPlayer.colliding = false;

                var n:int;
                for (n = 0; n < this.checkpoints.length; n++) {
                    checkpoint = this.checkpoints[n];
                    if (curCollider._getRect().overlaps(checkpoint._getRect())) {
                        this.overlapPlayerCheckpoints(curPlayer, checkpoint);
                    }
                }

                collisionData = FlxCollision.pixelPerfectCheck(
                    curCollider, this.collider, 255, null, curPlayer.collisionDirection, false);
                if (collisionData[0]) {
                    curPlayer.colliding = collisionData[0];
                }
            }
        }

        override public function destroy():void {
            super.destroy();
        }

        public function endRace():void {
            this.raceEndTimer = (this.raceTimeAlive/1000) + 3;
            this.finished = true;
            this.time_out_sprite.visible = true;
            this.gameActive = false;
        }

        public function overlapPlayerCheckpoints(player:Player,
                                                 checkpoint:Checkpoint):void
        {
            if(!this.finished) {
                player.crossCheckpoint(checkpoint, this.home_cp_index);
                if(player.winner) {
                    this.endRace();
                }
            }
        }

        private function setupWorld(bg:FlxSprite):void{
            var gravity:b2Vec2 = new b2Vec2(0, 0);
            m_world = new b2World(gravity, true);

            var dbgDraw:b2DebugDraw = new b2DebugDraw();
            var dbgSprite:Sprite = new Sprite();
            FlxG.stage.addChild(dbgSprite);
            dbgDraw.SetSprite(dbgSprite);
            dbgDraw.SetDrawScale(30 / 2);
            dbgDraw.SetFillAlpha(0.3);
            dbgDraw.SetLineThickness(1.0);
            dbgDraw.SetFlags(b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit);
            m_world.SetDebugDraw(dbgDraw);

            var ground:b2PolygonShape = new b2PolygonShape();
            var fixtureDef:b2FixtureDef = new b2FixtureDef();
            var groundBd:b2BodyDef = new b2BodyDef();

            groundBd.position.Set(0, 0);
            ground.SetAsBox(10 / m_physScale, 10 / m_physScale);
            groundBody = m_world.CreateBody(groundBd);
            fixtureDef.shape = ground;
            groundBody.CreateFixture2(ground);

            // Create border of boxes
            var wall:b2PolygonShape= new b2PolygonShape();
            var wallBd:b2BodyDef = new b2BodyDef();
            var wallB:b2Body;

            // Left
            wallBd.position.Set((bg.x - (100 - bg.width * .01)) / m_physScale, (bg.y + bg.height) / m_physScale);
            wall.SetAsBox(100 / m_physScale, bg.height / m_physScale);
            wallB = m_world.CreateBody(wallBd);
            wallB.CreateFixture2(wall);
            // Right
            wallBd.position.Set((bg.x + bg.width * 2 + (100 - bg.width * .01)) / m_physScale, (bg.y + bg.height) / m_physScale);
            wallB = m_world.CreateBody(wallBd);
            wallB.CreateFixture2(wall);
            // Top
            wallBd.position.Set((bg.x + bg.width) / m_physScale, ((bg.y + bg.height * .28) - (100 - bg.height * .01)) / m_physScale);
            wall.SetAsBox(bg.width / m_physScale, 100 / m_physScale);
            wallB = m_world.CreateBody(wallBd);
            wallB.CreateFixture2(wall);
            // Bottom
            wallBd.position.Set((bg.x + bg.width) / m_physScale, (bg.y + bg.height * 2.15) / m_physScale);
            wallB = m_world.CreateBody(wallBd);
            wallB.CreateFixture2(wall);
        }
    }
}
