package {
    import org.flixel.*;

    import flash.ui.GameInputControl;

    public class MenuState extends GameState {
        private var countdownLength:Number = 1, lastRegisterTime:Number = -1;
        private var stateSwitchLock:Boolean = false;
        private var registerIndicators:Array;

        private var curIndicator:RegistrationIndicator;

        override public function create():void {
            super.create();

            PlayersController.reset();
            ScreenManager.getInstance();

            this.registerIndicators = new Array();

            var t:FlxText;
            t = new FlxText(0, 200, ScreenManager.getInstance().screenWidth, "bootycall");
            t.size = 16;
            t.alignment = "left";
            add(t);
            t = new FlxText(0, 250, ScreenManager.getInstance().screenWidth, "join to play");
            t.alignment = "left";
            add(t);

            //PlayersController.getInstance().registerPlayer(null);
        }

        override public function update():void {
            super.update();

            if (PlayersController.getInstance().playersRegistered >= 2 &&
                (this.curTime - this.lastRegisterTime) / 1000 >
                 this.countdownLength && !this.stateSwitchLock)
            {
                this.stateSwitchLock = true;
                FlxG.switchState(new PlayState());
            }

            // debug
            if (FlxG.keys.justPressed("A")) {
                PlayersController.getInstance().registerPlayer(null, true);
                this.lastRegisterTime = this.curTime;
            }

            for (var i:int = 0; i < this.registerIndicators.length; i++) {
                this.curIndicator = this.registerIndicators[i];
                this.curIndicator.setPos(new DHPoint(
                    (ScreenManager.getInstance().screenWidth / (this.registerIndicators.length + 1)) * (i + 1),
                    ScreenManager.getInstance().screenHeight - 200
                ));
            }
        }

        override public function controllerChanged(control:GameInputControl,
                                                   mapping:Object):void
        {
            super.controllerChanged(control, mapping);
            if (control.id == mapping["a"] && control.value == 1) {
                var tagData:Object = PlayersController.getInstance().registerPlayer(control.device);
                if (tagData != null) {
                    this.lastRegisterTime = this.curTime;
                    var indicator:RegistrationIndicator = new RegistrationIndicator(
                        tagData
                    );
                    indicator.addVisibleObjects();
                    this.registerIndicators.push(indicator);
                }
            }
        }
    }
}
