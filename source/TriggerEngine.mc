using Toybox.Activity;
using Toybox.HeartRate;

class TriggerEngine {
  function initialize() {}

  function shouldTrigger(snapshot as Dictionary) as Boolean {
    var baseline = snapshot["baseline_hr"] as Number;
    var cooldownMinutes = snapshot["cooldown_minutes"] as Number;
    var lastTriggeredAt = snapshot["last_trigger_at"] as Number;
    var nowSeconds = snapshot["now_seconds"] as Number;

    if (!canTriggerByCooldown(lastTriggeredAt, nowSeconds, cooldownMinutes)) {
      return false;
    }

    var hr = safeHeartRateSample();
    if (hr <= 0) {
      return false;
    }

    if (!isUserLikelyInactive()) {
      return false;
    }

    return hr >= (baseline + AppConfig.HR_THRESHOLD_DELTA);
  }

  function canTriggerByCooldown(lastTriggeredAt as Number, nowSeconds as Number, cooldownMinutes as Number) as Boolean {
    if (lastTriggeredAt <= 0) {
      return true;
    }

    return (nowSeconds - lastTriggeredAt) >= (cooldownMinutes * 60);
  }

  function isUserLikelyInactive() as Boolean {
    var activity = Activity.getActivityInfo();
    if (activity == null || activity.elapsedTime == null) {
      return true;
    }

    return activity.elapsedTime >= AppConfig.INACTIVITY_SECONDS;
  }

  function safeHeartRateSample() as Number {
    var sample = HeartRate.getCurrentHeartRate();
    if (sample == null || sample <= 0) {
      return 0;
    }

    return sample;
  }
}
