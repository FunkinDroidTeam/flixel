package flixel.input;

import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.math.FlxVelocity;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxStringUtil;

/**
 * @author moondroidcoder
 * The flick management class used in FlxMouse and FlxTouchManager.
 * It handles all the flick motion, speed calculation, etc.
 */
@:allow(flixel.input.mouse.FlxMouse)
@:allow(flixel.input.touch.FlxTouchManager)
class FlxFlick implements IFlxDestroyable
{
	/**
	 * The threshold distance that needs to be surpassed for a flick to be returned as true.
	 * Can be set globally.
	 */
	public static var flickThreshold:FlxPoint;

	/**
	 * The max velocity the flicks are going to have.
	 * Can be set globally.
	 */
	public static var maxVelocity:FlxPoint;

	/**
	 * Either LEFT_MOUSE, MIDDLE_MOUSE or RIGHT_MOUSE,
	 * or the touchPointID of a FlxTouch.
	 */
	public var ID(default, null):Int;

	/**
	 * Whether the flick has been instanced or not.
	 */
	public var initialized:Bool = false;

	/**
	 * The speed of flicks (in pixels per second), usually gotten from an input source.
	 */
	public var velocity(default, null):FlxPoint;

	/**
	 * This isn't drag exactly, more like deceleration that is only applied
	 * when `acceleration` is not affecting the sprite.
	 */
	public var drag(default, null):FlxPoint;

	/**
	 * Whether a flick upwards has been passed or not.
	 */
	public var flickUp(get, default):Bool;

	/**
	 * Whether a flick downwards has been passed or not.
	 */
	public var flickDown(get, default):Bool;

	/**
	 * Indicates when a flick leftwards has been passed or not.
	 */
	public var flickLeft(get, default):Bool;

	/**
	 * Indicates when a flick rightwards has been passed or not.
	 */
	public var flickRight(get, default):Bool;

	// Helper variables for proper flick check so it helps performance to avoid handling the checks everytime you get the public check.

	/**
	 * Helper variable for proper flickUp checks.
	 */
	var _flickUp:Bool;

    /**
	 * Helper variable for proper flickDown checks.
	 */
	var _flickDown:Bool;

    /**
	 * Helper variable for proper flickLeft checks.
	 */
	var _flickLeft:Bool;

    /**
	 * Helper variable for proper flickRight checks.
	 */
	var _flickRight:Bool;

	/**
	 * The distance that has been passed while it calculates the motion
	 */
	var _currentDistance:FlxPoint;

	function new()
	{
		if (flickThreshold == null)
		{
			flickThreshold = FlxPoint.get(100, 100);
		}

		if (maxVelocity == null)
		{
			maxVelocity = FlxPoint.get(1000, 1000);
		}
	}

	/**
	 * Initialize the flick handling, usually triggered after a justReleased check.
     * It initializes every important variable needed for calculation the motion of the flicks.
	 * @param ID The TOUCH ID only for FlxTouch.
	 * @param StartingVelocity The starting velocity of the input.
	 * @param Drag How much drag for the velocity check, default is 700 pixels for both axes.
	 */
	public function initFlick(?ID:Int = -1, StartingVelocity:FlxPoint, ?Drag:FlxPoint):Void
	{
		if (initialized)
		{
			return;
		}

		this.ID = ID;
		velocity = StartingVelocity.clone();
		drag = (Drag != null) ? Drag.clone() : FlxPoint.get(700, 700);
		_currentDistance = FlxPoint.get();

		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
		{
			if (touch == null || touch.touchPointID != ID)
			{
				continue;
			}

			if (Math.abs(touch.deltaX) <= 25)
			{
				velocity.x = 0;
			}

			if (Math.abs(touch.deltaY) <= 25)
			{
				velocity.y = 0;
			}
			break;
		}
		#end

		initialized = true;
	}

	/**
	 * Updates the flick management.
	 * @param elapsed Time elapsed.
	 */
	public function update(elapsed:Float) {
		if (!initialized)
		{
			return;
		}

		if (Math.abs(velocity.x) + Math.abs(velocity.y) <= 10)
		{
			destroy();
			return;
		}

		updateMotion(elapsed);

		var modifiedDistance = _currentDistance.x;

		if (Math.abs(_currentDistance.x) > flickThreshold.x)
		{
			#if FLX_TOUCH
			if (FlxG.touches.invertX)
				modifiedDistance = -_currentDistance.x;
			#end

			if (modifiedDistance < 0)
			{
				_flickLeft = true;
			}
			else
			{
				_flickRight = true;
			}
			_currentDistance.x = 0;
		}

		modifiedDistance = _currentDistance.y;

		if (Math.abs(_currentDistance.y) > flickThreshold.y)
		{
			#if FLX_TOUCH
			if (FlxG.touches.invertY)
				modifiedDistance = -_currentDistance.y;
			#end

			if (modifiedDistance < 0)
			{
				_flickDown = true;
			}
			else
			{
				_flickUp = true;
			}
			_currentDistance.y = 0;
		}
	}

	/**
	 * Updates the motion of the flick.
     * Uses a framerate dependent calculation.
	 * @param elapsed Time elapsed
	 */
	@:noCompletion
	function updateMotion(elapsed:Float):Void
	{
		if (Math.abs(velocity.x) + Math.abs(velocity.y) <= 10)
		{
			destroy();
			return;
		}

		var framerateAmp = 60 / (FlxG.updateFramerate > 60 ? FlxG.updateFramerate : 60) - 0.05;
		if (framerateAmp > 0.45) framerateAmp = 0.45;

		var newVelocity = FlxVelocity.computeVelocity(velocity.x, 0, drag.x, maxVelocity.x, elapsed);
		var avgVelocity = 0.5 * (velocity.x + newVelocity);
		velocity.x = newVelocity;
		_currentDistance.x += (avgVelocity * elapsed) / framerateAmp;

		newVelocity = FlxVelocity.computeVelocity(velocity.y, 0, drag.y, maxVelocity.y, elapsed);
		avgVelocity = 0.5 * (velocity.y + newVelocity);
		velocity.y = newVelocity;
		_currentDistance.y += (avgVelocity * elapsed) / framerateAmp;
	}

	/**
	 * This is not a proper destroy function.
	 * It destroys the motion variables and sets `intiliazed` to false.
	 */
	public function destroy()
	{
		velocity = FlxDestroyUtil.put(velocity);
		drag = FlxDestroyUtil.put(drag);
		_currentDistance = FlxDestroyUtil.put(_currentDistance);
		initialized = false;
	}

	@:noCompletion
	inline function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("ID", ID),
			LabelValuePair.weak("velocity", velocity),
			LabelValuePair.weak("drag", drag),
			LabelValuePair.weak("flickThreshold", flickThreshold),
			LabelValuePair.weak("currentDistance", _currentDistance),
		]);
	}

	@:noCompletion
	function get_flickUp():Bool {
		if (_flickUp)
		{
			_flickUp = false;
			return true;
		}
		return false;
	}

	@:noCompletion
	function get_flickDown():Bool {
		if (_flickDown)
		{
			_flickDown = false;
			return true;
		}
		return false;
	}

	@:noCompletion
	function get_flickLeft():Bool {
		if (_flickLeft)
		{
			_flickLeft = false;
			return true;
		}
		return false;
	}

	@:noCompletion
	function get_flickRight():Bool {
		if (_flickRight)
		{
			_flickRight = false;
			return true;
		}
		return false;
	}
}
