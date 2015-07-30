package {
    import org.flixel.*;

    import flash.ui.GameInputControl;
    import flash.ui.GameInputDevice;

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
            if (FlxG.keys.justPressed("SPACE")) {
                this.registerPlayer(null, Player.CTRL_KEYBOARD_1);
            } else if (FlxG.keys.justPressed("P")) {
                this.registerPlayer(null, Player.CTRL_KEYBOARD_2);
            }

            for (var i:int = 0; i < this.registerIndicators.length; i++) {
                this.curIndicator = this.registerIndicators[i];
                this.curIndicator.setPos(new DHPoint(
                    (ScreenManager.getInstance().screenWidth / (this.registerIndicators.length + 1)) * (i + 1),
                    ScreenManager.getInstance().screenHeight - 200
                ));
            }
        }

        override public function controllerChanged(control:Object,
                                                   mapping:Object):void
        {
            super.controllerChanged(control, mapping);
            if (control['id'] == mapping["a"]["button"] && control['value'] == mapping["a"]["value_on"]) {
                this.registerPlayer(control, Player.CTRL_PAD);
            }
        }

        public function registerPlayer(control:Object,
                                       ctrlType:Number=Player.CTRL_PAD):void
        {
            var device:GameInputDevice;
            if (control == null) {
                device = null;
            } else {
                device = control.device;
            }
            var tagData:Object = PlayersController.getInstance().registerPlayer(
                device, ctrlType);
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
