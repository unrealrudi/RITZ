package;

import Dust;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.FlxObject;
import flixel.FlxG;
import flixel.FlxSprite;

class Player extends FlxSprite
{
    static inline var USE_NEW_SETTINGS = true;
    
    static inline var TILE_SIZE = 32;
    static inline var MAX_APEX_TIME = USE_NEW_SETTINGS ? 0.35 : 0.35;
    static inline var MIN_JUMP  = TILE_SIZE * (USE_NEW_SETTINGS ? 1.5 : 2.5);
    static inline var MAX_JUMP  = TILE_SIZE * (USE_NEW_SETTINGS ? 3.5 : 4.5);
    static inline var AIR_JUMP  = TILE_SIZE * (USE_NEW_SETTINGS ? 2.0 : 2.0);
    static inline var FALL_JUMP = TILE_SIZE * (USE_NEW_SETTINGS ? 3.0 : 4.0);
    
    static inline var MIN_APEX_TIME = 2 * MAX_APEX_TIME * MIN_JUMP / (MIN_JUMP + MAX_JUMP);
    static inline var GRAVITY = 2 * MIN_JUMP / MIN_APEX_TIME / MIN_APEX_TIME;
    static inline var JUMP_SPEED = -2 * MIN_JUMP / MIN_APEX_TIME;
    static inline var JUMP_HOLD_TIME = (MAX_JUMP - MIN_JUMP) / -JUMP_SPEED;
    static var airJumpSpeed(default, never) = -Math.sqrt(2 * GRAVITY * AIR_JUMP);
    
    inline static var JUMP_DISTANCE = TILE_SIZE * (USE_NEW_SETTINGS ? 5 : 5);
    inline static var SLOW_DOWN_TIME       = (USE_NEW_SETTINGS ? 0.5 : 0.32);
    inline static var GROUND_SPEED_UP_TIME = (USE_NEW_SETTINGS ? 0.2 : 0.16);
    inline static var AIRHOP_SPEED_UP_TIME = (USE_NEW_SETTINGS ? 0.5 : 0.5);
    
    inline static var MAXSPEED = JUMP_DISTANCE / MAX_APEX_TIME / 2;
    inline static var GROUND_ACCEL = MAXSPEED / GROUND_SPEED_UP_TIME;
    inline static var AIRHOP_ACCEL = MAXSPEED / AIRHOP_SPEED_UP_TIME;
    inline static var DRAG = MAXSPEED / SLOW_DOWN_TIME;
    
    private var baseJumpStrength:Float = 120;
    private var apexReached:Bool = true;

    // Not a boost per se, simply a counter for the cos wave thing
    private var jumpBoost:Int = 0;

    public var gettingHurt:Bool = false;


    static inline var COYOTE_TIME = 8 / 60;
    private var coyoteTimer:Float = 0;
    private var doubleJumped:Bool = false;
    private var jumped:Bool = false;
    private var jumpTimer:Float = 0;
    private var hovering:Bool = false;
    private var wallClimbing:Bool = false;
    public var onGround   (default, null):Bool = false;
    public var wasOnGround(default, null):Bool = false;
    public var onCoyoteGround   (default, null):Bool = false;
    
    public var dust:FlxTypedGroup<Dust> = new FlxTypedGroup();

    var left:Bool;
    var right:Bool;
    var jump:Bool;
    var jumpP:Bool;
    var down:Bool;

    public function new(x:Float, y:Float):Void
    {
        super(x, y);

        loadGraphic(AssetPaths.ritz_spritesheet__png, true, 32, 32);
        animation.add('idle', [0]);
        animation.add('walk', [1, 2, 2, 0], 12);
        animation.add('jumping', [2]);
        animation.add('skid', [3]);
        animation.add('falling', [4]);
        animation.add('fucking died lmao', [7, 8, 9, 10, 11], 12);

        animation.play("idle");

        height -= 8;
        offset.y = 6;
        width -= 16;
        offset.x = 8;

        setFacingFlip(FlxObject.LEFT, false, false);
        setFacingFlip(FlxObject.RIGHT, true, false);

        drag.x = DRAG;
        maxVelocity.x = MAXSPEED;
        maxVelocity.y = -JUMP_SPEED;
    }

    override public function update(elapsed:Float):Void
    {

        if (!wallClimbing)
        {
            acceleration.y = GRAVITY;
            drag.y = 2000;
        }
        else
        {
            if (velocity.y > 0)
                drag.y = 1000;
            else
                drag.y = 1200;
        }

        if (gettingHurt)
        {
            velocity.set();
            acceleration.set();
        }
        else
        {
            movement(elapsed);
        }
        super.update(elapsed);
    }

    private function movement(elapsed:Float):Void
    {
        left = FlxG.keys.anyPressed(['LEFT', 'A']);
        right = FlxG.keys.anyPressed(['RIGHT', 'D']);
        jump = FlxG.keys.anyPressed(['SPACE', 'W', 'UP', 'Z', 'Y']);
        jumpP = FlxG.keys.anyJustPressed(['SPACE', "W", 'UP', 'Z', 'Y']);
        down = FlxG.keys.anyPressed(['S', 'DOWN']);
        
        wasOnGround = onGround;
        onGround = isTouching(FlxObject.FLOOR);
        if (onGround)
        {
            coyoteTimer = 0;
            onCoyoteGround = true;
            
            if (!wasOnGround)
                makeDust(Land);
        }
        else if (coyoteTimer < COYOTE_TIME)
        {
            coyoteTimer += elapsed;
            onCoyoteGround = true;
        }
        else
            onCoyoteGround = false;

        // THESE VARIABLES HAVE UNDERSCORES SIMPLY BECAUSE I COPY PASTED IT FROM CITYHOPPIN LMAOOO
        // https://github.com/ninjamuffin99/cityhoppin/blob/master/source/player/Player4Keys.hx
        var _upR:Bool = false;
		var _downR:Bool = false;
		var _leftR:Bool = false;
		var _rightR:Bool = false;
		
		_upR = FlxG.keys.anyJustReleased([UP, W, SPACE, Z, Y]);
		_downR = FlxG.keys.anyJustReleased([DOWN, S]);
		_leftR = FlxG.keys.anyJustReleased([LEFT, A]);
        _rightR = FlxG.keys.anyJustReleased([RIGHT, D]);
        

		var _downP:Bool = false;
		var _leftP:Bool = false;
		var _rightP:Bool = false;
		
		_downP = FlxG.keys.anyJustPressed([DOWN, S]);
		_leftP = FlxG.keys.anyJustPressed([LEFT, A]);
        _rightP = FlxG.keys.anyJustPressed([RIGHT, D]);

        var gamepad = FlxG.gamepads.lastActive;
		if (gamepad != null)
		{
			if (gamepad.anyPressed(["LEFT", "DPAD_LEFT", "LEFT_STICK_DIGITAL_LEFT"]))
			{
				left = true;
			}
			
			if (gamepad.anyPressed(["RIGHT", "DPAD_RIGHT","LEFT_STICK_DIGITAL_RIGHT"]))
			{
				right = true;
			}

            if (gamepad.anyPressed([A]))
			{
				jump = true;
			}
			
			if (gamepad.anyPressed(["DOWN", "DPAD_DOWN","LEFT_STICK_DIGITAL_DOWN"]))
			{
				down = true;
			}

            if (gamepad.anyJustPressed(["LEFT", "DPAD_LEFT", "LEFT_STICK_DIGITAL_LEFT"]))
			{
				_leftP = true;
			}
			
			if (gamepad.anyJustPressed(["RIGHT", "DPAD_RIGHT","LEFT_STICK_DIGITAL_RIGHT"]))
			{
				_rightP = true;
			}

            if (gamepad.anyJustPressed([A]))
			{
				jumpP = true;
			}
			
			if (gamepad.anyJustPressed(["DOWN", "DPAD_DOWN","LEFT_STICK_DIGITAL_DOWN"]))
			{
				_downP = true;
			}

		}
        
        if (isTouching(FlxObject.CEILING) || _upR)
            apexReached = true;
        
            
        
        if ((left != right))
        {
            var accel:Float = GROUND_ACCEL;
            if (!onCoyoteGround && doubleJumped && velocity.y > 0)
                accel = AIRHOP_ACCEL;

            // if (hovering)
            //     hoverMulti = 0.6;
            
            acceleration.x = (left ? -1 : 1) * accel;
        }
        else
            acceleration.x = 0;
        
        if (velocity.x != 0)
        {
            facing = velocity.x > 0 ? FlxObject.RIGHT : FlxObject.LEFT;
            if (acceleration.x == 0 || FlxMath.sameSign(velocity.x, acceleration.x))
                animation.play('walk');
            else
            {
                if (animation.curAnim.name == "walk")
                    makeDust(Skid);
                animation.play('skid');
            }
        }
        else if (acceleration.x == 0)
            animation.play('idle');

        //wallJumping();      
        
        if (onCoyoteGround)
        {
            doubleJumped = false;
            jumped = false;
            hovering = false;
            apexReached = false;
            jumpBoost = 0;
            jumpTimer = 0;

            if (jumpP)
            {
                //velocity.y -= 480;
                // velocity.y -= baseJumpStrength * 2;
                velocity.y = JUMP_SPEED;
                jumped = true;
                onGround = false;
                onCoyoteGround = false;
                wasOnGround = true;
                FlxG.sound.play('assets/sounds/jump' + BootState.soundEXT, 0.5);
                coyoteTimer = COYOTE_TIME;
            }   
        }
        else
        {
            animation.play(velocity.y < 0 ? 'jumping' : "falling");
            
            // variableJump_old(elapsed);
            variableJump_new(elapsed);
            
            
            if (jumpP && !doubleJumped && !wallClimbing)
            {
                velocity.y = 0;
                if ((velocity.x > 0 && left) || (velocity.x < 0 && right))
                {
                    // sorta sidejump style boost thingie
                    //velocity.y -= 200;
                    //velocity.x *= -0.1;
                }
                    
                // velocity.y = -600;
                velocity.y = airJumpSpeed;
                doubleJumped = true;
                FlxG.sound.play('assets/sounds/doubleJump' + BootState.soundEXT, 0.75);
            }
        }

        
        
        /* 
        if (doubleJumped && velocity.y > 0)
        {
            drag.x = 200;

            if (jump)
            {
                hovering = true;
            }
            else
            {
                hovering = false;
            }
        }
        */

        if (wallClimbing)
        {
            doubleJumped = false;
            hovering = false;
        }
            


        if (hovering)
        {
            velocity.y = 100;
            drag.x = 150;
        }
        else
        {
            drag.x = 1700;
        }
        
        
    }
    
    function variableJump_new(elapsed:Float):Void
    {
        if (jump && !apexReached)
        {
            jumpTimer += elapsed;
            if (jumpTimer < JUMP_HOLD_TIME)
                velocity.y = JUMP_SPEED;
            else
                apexReached = true;
        }
    }
    
    function variableJump_old(elapsed:Float):Void
    {
        
        if (jump && !apexReached)
        {
            jumpBoost++;

            var C = FlxMath.fastCos(10.7 * jumpBoost * FlxG.elapsed);
            FlxG.watch.addQuick('Cos', C);
            if (C < 0)
            {
                apexReached = true;
            }
            else
            {
                velocity.y -= C * (baseJumpStrength * 1.6) * 2;
            }
        }
    }

    private function wallJumping():Void
    {
        if (isTouching(FlxObject.WALL))
        {
            
            if (jump && down)
                jump = down = false;
            
            if (jump || down)
            {
                if (jump)
                {
                    acceleration.y = -GROUND_ACCEL * 0.8;
                }
    
                if (down)
                {
                    acceleration.y = 900;
                }
            }
            else
            {
                acceleration.y = 0;
            }
            
    
    
            wallClimbing = true;
        }
        else
        {
            wallClimbing = false;
        }

    }
    
    function makeDust(type:DustType):Dust
    {
        var newDust = dust.recycle(Dust);
        newDust.place(type, x + width / 2, y + height, flipX);
        if (type == Skid)
        {
            newDust.x += (flipX ? 1 : -1) * width;
            newDust.velocity.x = velocity.x / 4;
            newDust.drag.x = Math.abs(newDust.velocity.x) * 2;
        }
        return newDust;
    }
}