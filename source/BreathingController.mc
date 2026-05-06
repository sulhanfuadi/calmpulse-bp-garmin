using Toybox.Attention;
using Toybox.Timer;

class BreathingController {
  var _timer;
  var _elapsed;
  var _isActive;

  function initialize() {
    _elapsed = 0;
    _isActive = false;
  }

  function start(onTick as Method) as Void {
    stop();
    _elapsed = 0;
    _isActive = true;

    if (_timer == null) {
      _timer = new Timer.Timer();
    }

    _timer.start(onTick, AppConfig.BREATHING_TICK_SECONDS, true);
  }

  function stop() as Void {
    if (_timer != null) {
      _timer.stop();
    }
    _isActive = false;
  }

  function tick() as Void {
    _elapsed += 1;
    if ((_elapsed % AppConfig.BREATHING_PACE_SECONDS) == 0) {
      Attention.vibrate([new Attention.VibeProfile(AppConfig.VIBE_BREATHING_INTENSITY, AppConfig.VIBE_BREATHING_DURATION_MS)]);
    }
  }

  function completeHaptic() as Void {
    Attention.vibrate([new Attention.VibeProfile(AppConfig.VIBE_COMPLETE_INTENSITY, AppConfig.VIBE_COMPLETE_DURATION_MS)]);
  }

  function elapsed() as Number {
    return _elapsed;
  }

  function isDone() as Boolean {
    return _elapsed >= AppConfig.BREATH_DURATION_SECONDS;
  }

  function isActive() as Boolean {
    return _isActive;
  }
}
