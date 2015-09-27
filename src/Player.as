package {
    import org.flixel.*;

    import Box2D.Dynamics.*;
    import Box2D.Collision.*;
    import Box2D.Collision.Shapes.*;
    import Box2D.Common.Math.*;
    import Box2D.Dynamics.Joints.*;

    import flash.ui.GameInputDevice;
    import flash.ui.GameInputControl;
    import flash.utils.Dictionary;

    public class Player extends GameObject {
        [Embed(source="/../assets/audio/drive.mp3")] private var SfxAccel:Class;
        [Embed(source="/../assets/audio/donk.mp3")] private var SfxEnd:Class;
        [Embed(source="/../assets/audio/collide.mp3")] private var SfxCollide:Class;
        [Embed(source="/../assets/audio/passenger.mp3")] private var SfxPassenger:Class;
        [Embed(source="/../assets/images/ui/HUD_arrow.png")] private static var HUDCheckmark:Class;
        [Embed(source="/../assets/images/misc/highlight.png")] private static var ImgHighlight:Class;
        [Embed(source="/../assets/images/ui/HUD_TempHeart.png")] private static var HUDHeart:Class;

        public static const COLLISION_TAG:String = "car_thing";

        // the player's maximum velocity
        private static const MAX_VELOCITY:Number = 500;
        // factor in acceleration. higher == faster acceleration, tighter turns
        private static const ACCELERATION_MULTIPLIER:Number = 1.5;
        // the amount of drag generated by the road
        private static const ROAD_DRAG:Number = 25;

        private var m_physScale:Number = 30
        private var m_physBody:b2Body,
                    m_groundBody:b2Body;
        private var m_world:b2World;
        private var driver_sprite:Class;
        private var highlight_sprite:GameObject;
        private var carSprite:GameObject;
        private var mainSprite:GameObject;
        private var collider:GameObject;
        public var playerConfig:Object;
        private var checkmark_sprite:GameObject;
        private var heart_sprite:GameObject;
        private var controller:GameInputDevice;
        private var startPos:DHPoint;
        private var passengers:Array;
        private var accel:DHPoint,
                    directionsPressed:DHPoint,
                    throttle:Boolean,
                    facingVector:DHPoint;
        private var _colliding:Boolean = false;
        private var _collisionDirection:Array,
                    _checkpointStatusList:Array;
        private var completionIndicator:FlxText;
        private var _driver_name:String;
        private var driver_tag:Number, frameRate:Number = 12,
                    completionTime:Number = -1,
                    checkInTime:Number = 0,
                    no_date_text_timer:Number = 0;
        private var _checkpoints_complete:Boolean = false,
                    _winner:Boolean = false,
                    _race_started:Boolean = false,
                    play_heart:Boolean = false,
                    heart_scale_down:Boolean = false;
        private var _lastCheckpointIdx:Number = 0;
        private var player_hud:PlayerHud;
        private var _driving:Boolean = false;
        private var checking_in:Boolean = false;
        private var lastPassengerRemoveTime:Number = 0;
        private var passengerRemoveThreshold:Number = 1;
        private var curCheckpoint:Checkpoint;
        private var lastCompletedCheckpoint:Checkpoint;
        private var curHomeInd:Number;
        private var meter:Meter;
        private var streetPoints:Array;
        private var impactParticles:ParticleExplosion;
        private var heartParticles:Array;
        private var lastHeartParticleRun:Number = 0,
                    heartParticleInterval:Number = .2,
                    curHeartParticleIndex:Number = 0;
        private var exhaustParticles:Array;
        private var lastExhaustParticleRun:Number = 0,
                    exhaustParticleInterval:Number = .2,
                    curExhaustParticleIndex:Number = 0;
        private var exhaustPos:DHPoint;
        private var car_sprite:Class;
        private var no_date_text:FlxText;

        {
            public static const CTRL_PAD:Number = 1;
            public static const CTRL_KEYBOARD_1:Number = 2;
            public static const CTRL_KEYBOARD_2:Number = 3;
            private static var keyboardControls:Dictionary = new Dictionary();
            keyboardControls[CTRL_KEYBOARD_1] = {
                'up': "W",
                'down': "S",
                'left': "A",
                'right': "D",
                'throttle': "R",
                'highlight': "E"
            };
            keyboardControls[CTRL_KEYBOARD_2] = {
                'up': "I",
                'down': "K",
                'left': "J",
                'right': "L",
                'throttle': "P",
                'highlight': "O"
            };
        }

        private var controlType:Number = CTRL_PAD;
        private var accelSFX:FlxSound;
        private var lastCheckpointSound:FlxSound;
        private var collideSfx:FlxSound;
        private var passengerSfx:FlxSound;

        public function Player(pos:DHPoint,
                               controller:GameInputDevice,
                               _world:b2World,
                               groundBody:b2Body,
                               streetPoints:Array,
                               ctrlType:Number=CTRL_PAD,
                               _tag:Number=0,
                               checkpoint_count:Number=0):void
        {
            super(pos);

            this.playerConfig = PlayersController.getInstance().playerConfigs[_tag];

            this.m_world = _world;
            this.m_groundBody = groundBody;
            this.dir = new DHPoint(0, 0);
            this.accel = new DHPoint(0, 0);
            this.directionsPressed = new DHPoint(0, 1);
            this.facingVector = new DHPoint(0, 1);
            this.throttle = false;
            this.controlType = ctrlType;
            this.streetPoints = streetPoints;

            this.controller = controller;
            this.driver_tag = _tag;

            var tagData:Object = PlayersController.getInstance().resolveTag(this.driver_tag);
            this.driver_sprite = tagData['sprite'];
            this._driver_name = tagData['name'];
            this.car_sprite = tagData['car'];
            this._checkpointStatusList = new Array();

            this.passengers = new Array();

            this.addAnimations();

            this.accelSFX = new FlxSound();
            this.accelSFX.loadEmbedded(SfxAccel, false);
            this.accelSFX.volume = 1;

            this.lastCheckpointSound = new FlxSound();
            this.lastCheckpointSound.loadEmbedded(SfxEnd, false);
            this.lastCheckpointSound.volume = 1;

            this.collideSfx = new FlxSound();
            this.collideSfx.loadEmbedded(SfxCollide, false);
            this.collideSfx.volume = 1;

            this.passengerSfx = new FlxSound();
            this.passengerSfx.loadEmbedded(SfxPassenger, false);
            this.passengerSfx.volume = 1;

            this.completionIndicator = new FlxText(this.pos.x, this.pos.y - 30, 200, "");
            this.completionIndicator.setFormat(null, 20, 0xffd82e5a, "center");
            this.no_date_text = new FlxText(this.pos.x, this.pos.y - 30, 200, "I need a date!");
            this.no_date_text.setFormat(null, 20, 0xffd82e5a, "center");
            this.no_date_text.visible = false;

            this._checkpointStatusList = new Array();

            for(var i:Number = 0; i < checkpoint_count; i++) {
                this._checkpointStatusList.push(false);
            }

            this.collider = new GameObject(new DHPoint(0, 0), this);
            this.collider.makeGraphic(this.mainSprite.width,
                                      this.mainSprite.height * .5,
                                      0xffffff00,
                                      true);
            this.collider.visible = false;

            this.setupPhysics();

            this._collisionDirection = new Array(0, 0, 0, 0);
            this.meter = new Meter(this.pos, 100, 50, 10);
            this.meter.setVisible(false);
            this.setupParticles();
        }

        public function getFacingVector():DHPoint {
            return this.facingVector;
        }

        public function setHudPos(pos:DHPoint):void {
            this.player_hud.setPos(pos);
        }

        public function setupParticles():void {
            impactParticles = new ParticleExplosion(13, 2, .4, 12);
            impactParticles.gravity = new DHPoint(0, .3);

            var i:int = 0;

            this.heartParticles = new Array();
            var hearts:ParticleExplosion;
            for (i = 0; i < 5; i++) {
                hearts = new ParticleExplosion(13, 3, .6, 15, 2, .7, null, 0,
                                               Particle.TYPE_HEART);
                hearts.gravity = new DHPoint(0, 0);
                this.heartParticles.push(hearts);
            }

            this.exhaustParticles = new Array();
            var exhaust:ParticleExplosion;
            for (i = 0; i < 5; i++) {
                exhaust = new ParticleExplosion(5, 4, .8, 10, 1, .7,
                                                this.carSprite, 1,
                                                Particle.TYPE_EXHAUST);
                exhaust.gravity = new DHPoint(0,0);
                this.exhaustParticles.push(exhaust);
            }
        }

        public function overlapsPassenger(passenger:Passenger):Boolean {
            return this.carSprite._getRect().overlaps(passenger.getStandingHitbox());
        }

        public function removePassenger(hitVector:DHPoint):void {
            if (this.timeAlive - this.lastPassengerRemoveTime < this.passengerRemoveThreshold) {
                return;
            }
            var lastPassenger:Object;
            if (this.passengers.length > 0) {
                lastPassenger = this.passengers.pop();
                this.lastPassengerRemoveTime = this.timeAlive;
            }
            if (lastPassenger != null) {
                var destPoint:DHPoint = this.streetPoints[
                    Math.floor(Math.random() * (this.streetPoints.length - 1))];
                lastPassenger.leaveCar(hitVector, destPoint);
                this.impactParticles.run(this.getMiddle());
            }
            if (this.passengers.length == 0) {
                this.checking_in = false;
                this.meter.setVisible(false);
            }
            this.collideSfx.play();
        }

        public function addPassenger(passenger:Passenger):void {
            if (passenger.driver != null) {
                return;
            }
            passenger.enterCar(this);
            this.passengers.push(passenger);
            passenger.idx = this.passengers.indexOf(passenger);
            passengerSfx.play();
        }

        public function getPassengers():Array {
            return this.passengers;
        }

        public function get bodyVelocity():Number {
            return this.m_physBody.GetAngularVelocity();
        }

        public function get bodyLinearVelocity():DHPoint {
            var vel:b2Vec2 = this.m_physBody.GetLinearVelocity();
            return new DHPoint(vel.x * m_physScale, vel.y * m_physScale);
        }

        public function setupPhysics():void {
            var box:b2PolygonShape = new b2PolygonShape();
            box.SetAsBox((this.collider.width * .6) / m_physScale,
                         (this.collider.height * .8) / m_physScale);
            var fixtureDef:b2FixtureDef = new b2FixtureDef();
            fixtureDef.shape = box;
            fixtureDef.density = 0.5;
            fixtureDef.restitution = 0.5;
            fixtureDef.userData = {'tag': COLLISION_TAG, 'player': this};
            var bd:b2BodyDef = new b2BodyDef();
            bd.type = b2Body.b2_dynamicBody;
            bd.position.Set(this.pos.x / m_physScale, (this.pos.y) / m_physScale);
            bd.fixedRotation = true;
            m_physBody = this.m_world.CreateBody(bd);
            m_physBody.CreateFixture(fixtureDef);

            var jointDef:b2FrictionJointDef = new b2FrictionJointDef();
            jointDef.localAnchorA.SetZero();
            jointDef.localAnchorB.SetZero();
            jointDef.bodyA = m_physBody;
            jointDef.bodyB = m_groundBody;
            jointDef.maxForce = ROAD_DRAG;
            jointDef.maxTorque = 50;
            jointDef.collideConnected = true;
            m_world.CreateJoint(jointDef as b2JointDef);
        }

        public function addAnimations():void {
            var tagData:Object = PlayersController.getInstance().resolveTag(this.driver_tag);

            this.highlight_sprite = new GameObject(this.pos);
            this.highlight_sprite.zSorted = true;
            this.highlight_sprite.basePosOffset = new DHPoint(0, -10);
            this.highlight_sprite.loadGraphic(ImgHighlight, false, false, 64, 64);
            this.highlight_sprite.color = tagData["tint"];
            this.highlight_sprite.visible = false;

            this.carSprite = new GameObject(this.pos);
            this.carSprite.zSorted = true;
            this.carSprite.loadGraphic(car_sprite, false, false, 64, 64);
            this.carSprite.addAnimation("drive_right", [0,1,2,3], this.frameRate, true);
            this.carSprite.addAnimation("drive_up", [4,5,6,7], this.frameRate, true);
            this.carSprite.addAnimation("drive_down", [8,9,10,11], this.frameRate, true);
            this.carSprite.addAnimation("drive_left", [12,13,14,15], this.frameRate, true);
            this.carSprite.play("drive_down");

            this.mainSprite = new GameObject(this.pos, this);
            this.mainSprite.loadGraphic(driver_sprite, true, false, 64, 64);
            this.mainSprite.zSorted = true;
            this.mainSprite.basePosOffset = new DHPoint(
                this.mainSprite.width / 2,
                this.mainSprite.height * 5
            );
            this.mainSprite.addAnimation("drive_right", [0,1,2,3], this.frameRate, true);
            this.mainSprite.addAnimation("drive_up", [4,5,6,7], this.frameRate, true);
            this.mainSprite.addAnimation("drive_down", [8,9,10,11], this.frameRate, true);
            this.mainSprite.addAnimation("drive_left", [12,13,14,15], this.frameRate, true);
            this.mainSprite.play("drive_down");

            this.checkmark_sprite = new GameObject(new DHPoint(0, 0));
            this.checkmark_sprite.loadGraphic(HUDCheckmark, false, false, 32, 32);
            this.checkmark_sprite.visible = false;

            this.heart_sprite = new GameObject(new DHPoint(0,0));
            this.heart_sprite.loadGraphic(HUDHeart, false, false, 32, 24);
            this.heart_sprite.visible = false;
        }

        public function set colliding(c:Boolean):void {
            this._colliding = c;
        }

        public function get collisionDirection():Array {
            return this._collisionDirection;
        }

        public function set driving(r:Boolean):void {
            this._driving = r;
        }

        public function get driving():Boolean {
            return this._driving;
        }

        public function getCollider():GameObject {
            return this.collider;
        }

        override public function addVisibleObjects():void {
            super.addVisibleObjects();
            FlxG.state.add(this.highlight_sprite);
            FlxG.state.add(this.carSprite);
            FlxG.state.add(this.mainSprite);
            FlxG.state.add(this.completionIndicator);
            FlxG.state.add(this.no_date_text);
            FlxG.state.add(this.collider);
            this.player_hud = new PlayerHud(this.driver_tag);
            this.player_hud.buildHud();
            this.meter.addVisibleObjects();
            FlxG.state.add(this.checkmark_sprite);
            FlxG.state.add(this.heart_sprite);
            this.impactParticles.addVisibleObjects();
            var i:int = 0;
            for (i = 0; i < this.heartParticles.length; i++) {
                this.heartParticles[i].addVisibleObjects();
            }
            for (i = 0; i < this.exhaustParticles.length; i++) {
                this.exhaustParticles[i].addVisibleObjects();
            }
        }

        public function get lastCheckpointIdx():Number {
            return this._lastCheckpointIdx;
        }

        public function get checkpoints_complete():Boolean {
            return this._checkpoints_complete;
        }

        public function get driver_name():String {
            return this._driver_name;
        }

        public function get checkpointStatusList():Array {
            return this._checkpointStatusList;
        }

        public function get winner():Boolean {
            return this._winner;
        }

        public function get race_started():Boolean {
            return this._race_started;
        }

        public function set race_started(v:Boolean):void {
            this._race_started = v;
        }

        public function completeCheckpoint():void {
            this.checking_in = false;
            this.meter.setVisible(false);
            if(this.curCheckpoint.cp_type != Checkpoint.HOME) {
                this.lastCompletedCheckpoint = this.curCheckpoint;
                this._checkpointStatusList[this.curCheckpoint.index] = true;
                this.checkmark_sprite.visible = true;
                this.checkmark_sprite.setPos(this.pos);
                this.checkmark_sprite.setDir(
                    this.player_hud.posOf(this.curCheckpoint.cp_type).sub(this.pos).normalized().mulScl(14));
                this.playHeart();
            }
            var checkpointsComplete:Boolean = true;
            for (var n:Number = 0; n < this._checkpointStatusList.length; n++) {
                if(n != this.curHomeInd) {
                    if(!this._checkpointStatusList[n]) {
                        checkpointsComplete = false;
                    }
                }
            }
            if(!checkpointsComplete) {
                curCheckpoint.playSfx();
            }
            if(this.curCheckpoint.cp_type != Checkpoint.HOME) {
                if(checkpointsComplete) {
                    this.lastCheckpointSound.play();
                    this._checkpoints_complete = true;
                    this.completionTime = this.curTime;
                    this.completionIndicator.text = "Let's go home!";
                }
            }
        }

        public function playHeart():void {
            this.heart_sprite.scale = new DHPoint(.1,.1);
            this.heart_sprite.visible = true;
            this.heart_scale_down = false;
            this.heart_sprite.setPos(this.pos);
            this.play_heart = true;
        }

        public function crossCheckpoint(checkpoint:Checkpoint, home_ind:Number):void {
            if(!this._checkpoints_complete && !this.checking_in) {
                if (!this._checkpointStatusList[checkpoint.index] && checkpoint.cp_type != Checkpoint.HOME)
                {
                    if(this.passengers.length > 0) {
                        this.checkIn(checkpoint);
                        this.curCheckpoint = checkpoint;
                        this.curHomeInd = home_ind;
                    } else {
                        this.no_date_text.visible = true;
                        this.no_date_text_timer = (this.curTime + 5) / 1000;
                    }
                }
            } else if(this._checkpoints_complete && !this.checking_in){
                if(checkpoint.cp_type == Checkpoint.HOME) {
                    if(this.passengers.length > 0) {
                        this._winner = true;
                    } else {
                        this.no_date_text.visible = true;
                        this.no_date_text_timer = this.curTime + (5/1000);
                    }
                }
            }
        }


        public function checkIn(checkpoint:Checkpoint):void {
            this.meter.setVisible(true);
            this.checking_in = true;
            this.checkInTime = this.curTime;
        }

        public function checkOut():void {
            if(this.checking_in) {
                this.checking_in = false;
                this.meter.setVisible(false);
            }
        }

        override public function update():void {
            super.update();

            if(this.no_date_text.visible) {
                this.no_date_text.x = this.x - 50;
                this.no_date_text.y = this.y - 10;
                if(this.no_date_text_timer < this.curTime) {
                    this.no_date_text.visible = false;
                }
            }

            if (this.impactParticles != null) {
                this.impactParticles.update();
            }
            var p:int = 0;
            for (p = 0; p < this.heartParticles.length; p++) {
                if (this.heartParticles[p] != null) {
                    this.heartParticles[p].update();
                }
            }
            for (p = 0; p < this.exhaustParticles.length; p++) {
                if (this.exhaustParticles[p] != null) {
                    this.exhaustParticles[p].update();
                }
            }

            if (this._checkpoints_complete) {
                if ((this.curTime - this.lastHeartParticleRun) / 1000 > this.heartParticleInterval) {
                    this.lastHeartParticleRun = this.curTime;
                    this.heartParticles[this.curHeartParticleIndex].run(this.getMiddle());
                    if (this.curHeartParticleIndex >= this.heartParticles.length - 1) {
                        this.curHeartParticleIndex = 0;
                    } else {
                        this.curHeartParticleIndex += 1;
                    }
                }
            }

            if(this.play_heart) {
                this.heart_sprite.setPos(new DHPoint(this.pos.x + 15, this.pos.y - 20));
                if(this.heart_sprite.scale.x >= 1) {
                    this.heart_scale_down = true;
                }
                if(!this.heart_scale_down) {
                    this.heart_sprite.scale.x += .03;
                    this.heart_sprite.scale.y += .03;
                } else if(this.heart_scale_down) {
                    this.heart_sprite.scale.x -= .03;
                    this.heart_sprite.scale.y -= .03;
                    if(this.heart_sprite.scale.x <= 0) {
                        this.play_heart = false;
                        this.heart_sprite.visible = false;
                    }
                }
            }

            this.setPos(new DHPoint((this.m_physBody.GetPosition().x * m_physScale / 2) - this.mainSprite.width/2,
                                    (this.m_physBody.GetPosition().y * m_physScale / 2) - this.mainSprite.height/2));

            if(this.race_started) {
                if(this.driving) {
                    this.updateMovement();
                    this.updateDrivingAnimation();
                    if (this.controlType == CTRL_KEYBOARD_1 || this.controlType == CTRL_KEYBOARD_2) {
                        this.updateKeyboard(this.controlType);
                    }

                    if ((this.curTime - this.completionTime) / 1000 >= 2) {
                        this.completionIndicator.text = "";
                    }
                }
            } else {
                this.mainSprite.play("drive_down");
                this.carSprite.play("drive_down");
            }
            if(this.checking_in) {
                this.meter.setPos(this.pos.add(new DHPoint(30, -10)));
                this.meter.setPoints((((this.curTime - this.checkInTime)/1000)/3)*100);

                if ((this.curTime - this.checkInTime) / 1000 >= 3) {
                    this.completeCheckpoint()
                }
            }

            if (this.checkmark_sprite.visible && this.lastCompletedCheckpoint != null) {
                if (this.checkmark_sprite.getPos().sub(
                        this.player_hud.posOf(
                            this.lastCompletedCheckpoint.cp_type))._length() < 10)
                {
                    this.checkmark_sprite.visible = false;
                    this.player_hud.markCheckpoint(this.lastCompletedCheckpoint.cp_type);
                }
            }

            if(this.throttle) {
                if ((this.curTime - this.lastExhaustParticleRun) / 1000 > this.exhaustParticleInterval) {
                        this.lastExhaustParticleRun = this.curTime;
                        this.setExhaustPos();
                        this.exhaustParticles[this.curExhaustParticleIndex].run(this.exhaustPos);
                        if (this.curExhaustParticleIndex >= this.exhaustParticles.length - 1) {
                            this.curExhaustParticleIndex = 0;
                        } else {
                            this.curExhaustParticleIndex += 1;
                        }
                }
            }
        }

        public function updateMovement():void {
            if (this.throttle) {
                this.accelSFX.play();
                var force:b2Vec2, accelMul:Number = ACCELERATION_MULTIPLIER;
                if (this.directionsPressed.x != 0 || this.directionsPressed.y != 0) {
                    force = new b2Vec2(this.directionsPressed.x * accelMul, this.directionsPressed.y * accelMul);
                } else {
                    force = new b2Vec2(this.facingVector.x * accelMul, this.facingVector.y * accelMul);
                }
                if (this.bodyLinearVelocity._length() < MAX_VELOCITY) {
                    this.m_physBody.ApplyImpulse(force, this.m_physBody.GetPosition())
                }
            }

            if(!this.throttle) {
                this.accelSFX.stop();
            }

            if (this._colliding) {
                if (this._collisionDirection != null) {
                    if (this._collisionDirection[0] == 1 &&
                        this._collisionDirection[1] == 1 &&
                        this._collisionDirection[2] == 1 &&
                        this._collisionDirection[3] == 1)
                    {
                        // stuck!
                    } else {
                        if (this._collisionDirection[1] == 1) {
                            // right
                            this.m_physBody.SetLinearVelocity(
                                new b2Vec2(
                                    Math.min(this.m_physBody.GetLinearVelocity().x, 0),
                                    this.m_physBody.GetLinearVelocity().y
                                )
                            );
                        } else if (this._collisionDirection[0] == 1) {
                            // left
                            this.m_physBody.SetLinearVelocity(
                                new b2Vec2(
                                    Math.max(this.m_physBody.GetLinearVelocity().x, 0),
                                    this.m_physBody.GetLinearVelocity().y
                                )
                            );
                        }
                        if (this._collisionDirection[3] == 1) {
                            // down
                            this.m_physBody.SetLinearVelocity(
                                new b2Vec2(
                                    this.m_physBody.GetLinearVelocity().x,
                                    Math.min(this.m_physBody.GetLinearVelocity().y, 0)
                                )
                            );
                        } else if (this._collisionDirection[2] == 1) {
                            // up
                            this.m_physBody.SetLinearVelocity(
                                new b2Vec2(
                                    this.m_physBody.GetLinearVelocity().x,
                                    Math.max(this.m_physBody.GetLinearVelocity().y, 0)
                                )
                            );
                        }
                    }
                }
            }
            this._collisionDirection[0] = 0;
            this._collisionDirection[1] = 0;
            this._collisionDirection[2] = 0;
            this._collisionDirection[3] = 0;
        }

        public function updateDrivingAnimation():void {
            if(Math.abs(this.directionsPressed.x) > Math.abs(this.directionsPressed.y)) {
                if(this.throttle) {
                    if(this.directionsPressed.x >= 0) {
                        this.mainSprite.play("drive_right");
                        this.carSprite.play("drive_right");
                        this.facingVector.x = 1;
                        this.facingVector.y = 0;
                    } else {
                        this.mainSprite.play("drive_left");
                        this.carSprite.play("drive_left");
                        this.facingVector.x = -1;
                        this.facingVector.y = 0;
                    }
                }
            } else if(Math.abs(this.directionsPressed.y) > Math.abs(this.directionsPressed.x)) {
                if(this.throttle) {
                    if(this.directionsPressed.y >= 0) {
                        this.mainSprite.play("drive_down");
                        this.carSprite.play("drive_down");
                        this.facingVector.y = 1;
                        this.facingVector.x = 0;
                    } else {
                        this.mainSprite.play("drive_up");
                        this.carSprite.play("drive_up");
                        this.facingVector.y = -1;
                        this.facingVector.x = 0;
                    }
                }
            }
        }

        public function updateKeyboard(ctrlType:Number=CTRL_KEYBOARD_1):void {
            if (FlxG.keys.justPressed(keyboardControls[ctrlType]['right'])) {
                this.directionsPressed.x = 1;
            } else if (FlxG.keys.justReleased(keyboardControls[ctrlType]['right'])){
                this.directionsPressed.x = 0;
            }
            if (FlxG.keys.justPressed(keyboardControls[ctrlType]['left'])) {
                this.directionsPressed.x = -1;
            } else if (FlxG.keys.justReleased(keyboardControls[ctrlType]['left'])){
                this.directionsPressed.x = 0;
            }

            if (FlxG.keys.justPressed(keyboardControls[ctrlType]['up'])) {
                this.directionsPressed.y = -1;
            } else if (FlxG.keys.justReleased(keyboardControls[ctrlType]['up'])){
                this.directionsPressed.y = 0;
            }
            if (FlxG.keys.justPressed(keyboardControls[ctrlType]['down'])) {
                this.directionsPressed.y = 1;
            } else if (FlxG.keys.justReleased(keyboardControls[ctrlType]['down'])){
                this.directionsPressed.y = 0;
            }

            if (FlxG.keys.justPressed(keyboardControls[ctrlType]['throttle'])) {
                this.throttle = true;
            } else if (FlxG.keys.justReleased(keyboardControls[ctrlType]['throttle'])) {
                this.throttle = false;
            }

            if (FlxG.keys.justPressed(keyboardControls[ctrlType]['highlight'])) {
                this.highlight_sprite.visible = true;
            } else if (FlxG.keys.justReleased(keyboardControls[ctrlType]['highlight'])) {
                this.highlight_sprite.visible = false;
            }
        }

        public function controllerChanged(control:Object,
                                          mapping:Object):void
        {
            if (this.controller == null || control['device'].id != this.controller.id) {
                return;
            }

            if (control['id'] == mapping["right"]["button"]) {
                if (control['value'] == mapping["right"]["value_off"]) {
                    this.directionsPressed.x = 0;
                } else if (control['value'] == mapping["right"]["value_on"]) {
                    this.directionsPressed.x = 1;
                }
            }
            if (control['id'] == mapping["left"]["button"]) {
                if (control['value'] == mapping["left"]["value_off"]) {
                    this.directionsPressed.x = 0;
                } else if (control['value'] == mapping["left"]["value_on"]) {
                    this.directionsPressed.x = -1;
                }
            }
            if (control['id'] == mapping["up"]["button"]) {
                if (control['value'] == mapping["up"]["value_off"]) {
                    this.directionsPressed.y = 0;
                } else if (control['value'] == mapping["up"]["value_on"]){
                    this.directionsPressed.y = 1;
                }
            }
            if (control['id'] == mapping["down"]["button"]) {
                if (control['value'] == mapping["down"]["value_off"]) {
                    this.directionsPressed.y = 0;
                } else if(control['value'] == mapping["down"]["value_on"]) {
                    this.directionsPressed.y = -1;
                }
            }
            if (control['id'] == mapping["a"]["button"]) {
                if (control['value'] == mapping["a"]["value_on"]) {
                    this.throttle = true;
                } else if (control["value"] == mapping["a"]["value_off"]){
                    this.throttle = false;
                }
            }
            if (control['id'] == mapping["b"]["button"]) {
                if (control['value'] == mapping["b"]["value_on"]) {
                    this.highlight_sprite.visible = true;
                } else if (control["value"] == mapping["b"]["value_off"]){
                    this.highlight_sprite.visible = false;
                }
            }
        }

        override public function getMiddle():DHPoint {
            return this.mainSprite.getMiddle();
        }

        public function setExhaustPos():void {
            if(this.facingVector.x == 1) {
                //right
                this.exhaustPos = this.carSprite.getPos().add(new DHPoint(-10, this.carSprite.height/2));
            } else if(this.facingVector.x == -1) {
                //left
                this.exhaustPos = this.carSprite.getPos().add(new DHPoint(this.carSprite.width + 10, this.carSprite.height/2));
            } else if(this.facingVector.y == 1) {
                //down
                this.exhaustPos = this.carSprite.getPos().add(new DHPoint(this.carSprite.width/2, -10));
            } else if(this.facingVector.y == -1) {
                //up
                this.exhaustPos = this.carSprite.getPos().add(new DHPoint(this.carSprite.width/2, this.carSprite.height));
            }
        }

        override public function setPos(pos:DHPoint):void {
            super.setPos(pos);
            this.highlight_sprite.setPos(pos);
            this.mainSprite.setPos(pos);
            this.carSprite.setPos(pos);
            this.completionIndicator.x = pos.x;
            this.completionIndicator.y = pos.y - 10;
            this.collider.setPos(pos);
            this.collider.setPos(pos.add(
                new DHPoint(0,
                            this.mainSprite.height - this.collider.height)));

        }
    }
}
