package flixel.input.touch;

#if FLX_TOUCH
import openfl.geom.Point;
import flixel.FlxG;
import flixel.input.FlxInput;
import flixel.input.FlxSwipe;
import flixel.input.IFlxInput;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

/**
 * Helper class, contains and tracks touch points in your game.
 * Automatically accounts for parallax scrolling, etc.
 */
@:allow(flixel.input.touch.FlxTouchManager)
class FlxTouch extends FlxPointer implements IFlxDestroyable implements IFlxInput
{
	/**
	 * The _unique_ ID of this touch. You should not make not any further assumptions
	 * about this value - IDs are not guaranteed to start from 0 or ascend in order.
	 * The behavior may vary from device to device.
	 */
	public var touchPointID(get, never):Int;

	/**
	 * A value between 0.0 and 1.0 indicating force of the contact with the device. If the device does not support detecting the pressure, the value is 1.0.
	 */
	public var pressure(default, null):Float;

	/**
	 * Check to see if this touch has just been moved.
	 */
	public var justMoved(get, never):Bool;
	
	/**
	 * Check to see if this touch is currently pressed.
	 */
	public var pressed(get, never):Bool;
	/**
	 * Check to see if this touch has just been pressed.
	 */
	public var justPressed(get, never):Bool;
	/**
	 * Check to see if this touch is currently not pressed.
	 */
	public var released(get, never):Bool;
	
	/**
	 * Check to see if this touch has just been released.
	 */
	public var justReleased(get, never):Bool;

	/**
	 * Time in ticks of last press.
	 */
	public var justPressedTimeInTicks(default, null):Int = -1;

	/**
	 * Distance in pixels this touch has moved since the last frame in the X direction.
	 */
	public var deltaX(get, default):Float;
	/**
	 * Distance in pixels this touch has moved since the last frame in the Y direction.
	 */
	public var deltaY(get, default):Float;

	/**
	 * Distance in pixels this touch has moved in view space since the last frame in the X direction.
	 */
	public var deltaViewX(get, default):Float;
	/**
	 * Distance in pixels this touch has moved in view space since the last frame in the Y direction.
	 */
	public var deltaViewY(get, default):Float;

	/**
	 * The position of the touch when it was just pressed in FlxPoint.
	 */
	public var justPressedPosition(default, null) = FlxPoint.get();
	/**
	 * Time in ticks that had passed since of last press
	 */
	public var ticksDeltaSincePress(get, default):Int;

	/**
	 * Helper variables
	 */
	var input:FlxInput<Int>;
	
	var flashPoint = new Point();
	var _prevX:Float = 0;
	var _prevY:Float = 0;
	var _prevViewX:Float = 0;
	var _prevViewY:Float = 0;

	public function destroy():Void
	{
		input = null;
		justPressedPosition = FlxDestroyUtil.put(justPressedPosition);
		flashPoint = null;
	}

	/**
	 * Resets the justPressed/justReleased flags, sets touch to not pressed and sets touch pressure to 0.
	 */
	public function recycle(x:Int, y:Int, pointID:Int, pressure:Float):Void
	{
		setXY(x, y);
		input.ID = pointID;
		input.reset();
		this.pressure = pressure;
	}

	/**
	 * @param	X			stageX touch coordinate
	 * @param	Y			stageX touch coordinate
	 * @param	PointID		touchPointID of the touch
	 * @param	pressure	A value between 0.0 and 1.0 indicating force of the contact with the device. If the device does not support detecting the pressure, the value is 1.0.
	 */
	function new(x:Int = 0, y:Int = 0, pointID:Int = 0, pressure:Float = 0)
	{
		super();

		input = new FlxInput(pointID);
		setXY(x, y);
		this.pressure = pressure;
	}

	/**
	 * Called by the internal game loop to update the just pressed/just released flags.
	 */
	function update():Void
	{
		_prevX = x;
		_prevY = y;
		_prevViewX = viewX;
		_prevViewY = viewY;

		input.update();

		if (justPressed)
		{
			justPressedPosition.set(viewX, viewY);
			justPressedTimeInTicks = FlxG.game.ticks;
		}
		#if FLX_POINTER_INPUT
		else if (justReleased)
		{
			FlxG.swipes.push(new FlxSwipe(touchPointID, justPressedPosition.copyTo(), getViewPosition(), justPressedTimeInTicks));
		}
		#end
	}

	/**
	 * Function for updating touch coordinates. Called by the TouchManager.
	 *
	 * @param	X	stageX touch coordinate
	 * @param	Y	stageY touch coordinate
	 */
	function setXY(X:Int, Y:Int):Void
	{
		flashPoint.setTo(X, Y);
		flashPoint = FlxG.game.globalToLocal(flashPoint);

		setRawPositionUnsafe(flashPoint.x, flashPoint.y);
	}

	inline function get_touchPointID():Int
		return input.ID;

	inline function get_justReleased():Bool
		return input.justReleased;

	inline function get_released():Bool
		return input.released;

	inline function get_pressed():Bool
		return input.pressed;

	inline function get_justPressed():Bool
		return input.justPressed;

	inline function get_justMoved():Bool
		return x != _prevX || y != _prevY;

	inline function get_deltaX():Float
		return x - _prevX;

	inline function get_deltaY():Float
		return y - _prevY;

	inline function get_deltaViewX():Float
		return viewX - _prevViewX;

	inline function get_deltaViewY():Float
		return viewY - _prevViewY;
	inline function get_ticksDeltaSincePress():Int
		return FlxG.game.ticks - justPressedTimeInTicks;
}
#else
class FlxTouch {}
#end
