using Toybox.Activity;
using Toybox.Application;
using Toybox.Attention;
using Toybox.Graphics;
using Toybox.HeartRate;
using Toybox.Lang;
using Toybox.PersistedContent;
using Toybox.System;
using Toybox.Time;
using Toybox.Timer;
using Toybox.WatchUi;

class CalmPulseBPApp extends Application.AppBase {

  const KEY_BASELINE_HR = "baseline_hr";
  const KEY_LAST_TRIGGER_AT = "last_trigger_at";
  const KEY_COOLDOWN_MIN = "cooldown_minutes";
  const KEY_SESSION_LOG = "session_log";
  const KEY_DAILY_METRICS = "daily_metrics";
  const KEY_DISCLAIMER_ACK = "disclaimer_ack";
  const KEY_LAST_SESSION_COMPLETED = "last_session_completed";

  const STATE_ONBOARDING = "Onboarding";
  const STATE_IDLE = "Idle";
  const STATE_TRIGGERED = "Triggered";
  const STATE_BREATHING = "BreathingActive";
  const STATE_REFLECTION = "ReflectionPending";
  const STATE_SUMMARY = "Summary";

  const HR_THRESHOLD_DELTA = 14;
  const INACTIVITY_SECONDS = 600;
  const BREATH_DURATION_SECONDS = 60;

  var _state;
  var _baselineHr;
  var _lastTriggerAt;
  var _cooldownMinutes;
  var _sessionLog;
  var _dailyMetrics;

  var _monitorTimer;
  var _breathingTimer;
  var _breathingElapsed;

  function initialize() {
    AppBase.initialize();
    _state = STATE_ONBOARDING;
    _baselineHr = 0;
    _lastTriggerAt = 0;
    _cooldownMinutes = 45;
    _sessionLog = [];
    _dailyMetrics = {
      "trigger_count" => 0,
      "completion_count" => 0,
      "calming_rate" => 0.0
    };
    _breathingElapsed = 0;
  }

  function onStart(state as Dictionary?) as Void {
    loadPersistedState();

    if (!hasDisclaimerAck()) {
      _state = STATE_ONBOARDING;
    } else if (_baselineHr <= 0) {
      _state = STATE_ONBOARDING;
    } else {
      _state = STATE_IDLE;
      startMonitoring();
    }
  }

  function onStop(state as Dictionary?) as Void {
    if (_monitorTimer != null) { _monitorTimer.stop(); }
    if (_breathingTimer != null) { _breathingTimer.stop(); }
    persistState();
  }

  function getInitialView() as [Views] or [Views, InputDelegates] {
    return [ new CalmPulseBPView(self), new CalmPulseBPDelegate(self) ];
  }

  function getState() as String { return _state; }
  function getBaselineHr() as Number { return _baselineHr; }
  function getDailyMetrics() as Dictionary { return _dailyMetrics; }
  function getBreathingElapsed() as Number { return _breathingElapsed; }
  function getLastSessionCompleted() as Boolean { return Application.Storage.getValue(KEY_LAST_SESSION_COMPLETED, false); }

  function acknowledgeDisclaimerAndSetBaseline() as Void {
    var sample = HeartRate.getCurrentHeartRate();
    var value = (sample != null && sample > 0) ? sample : 72;
    _baselineHr = value;
    Application.Storage.setValue(KEY_DISCLAIMER_ACK, true);
    _state = STATE_IDLE;
    persistState();
    startMonitoring();
    WatchUi.requestUpdate();
  }

  function openSummary() as Void {
    _state = STATE_SUMMARY;
    WatchUi.requestUpdate();
  }

  function startMonitoring() as Void {
    if (_monitorTimer == null) { _monitorTimer = new Timer.Timer(); }
    _monitorTimer.start(method(:evaluateTrigger), 15, true);
  }

  function evaluateTrigger() as Void {
    if (_state != STATE_IDLE || !canTriggerByCooldown()) { return; }

    var hr = HeartRate.getCurrentHeartRate();
    if (hr == null || hr <= 0 || !isUserLikelyInactive()) { return; }

    if (hr >= (_baselineHr + HR_THRESHOLD_DELTA)) {
      markTriggered("hr_above_baseline_and_inactive");
    }
  }

  function canTriggerByCooldown() as Boolean {
    if (_lastTriggerAt <= 0) { return true; }
    var nowSeconds = Time.now().value();
    var elapsed = nowSeconds - _lastTriggerAt;
    return elapsed >= (_cooldownMinutes * 60);
  }

  function isUserLikelyInactive() as Boolean {
    var activity = Activity.getActivityInfo();
    if (activity == null || activity.elapsedTime == null) { return true; }
    return activity.elapsedTime >= INACTIVITY_SECONDS;
  }

  function markTriggered(reason as String) as Void {
    _state = STATE_TRIGGERED;
    _lastTriggerAt = Time.now().value();
    _dailyMetrics["trigger_count"] = (_dailyMetrics["trigger_count"] as Number) + 1;
    var vibe = new Attention.VibeProfile(50, 500);
    Attention.vibrate([vibe, vibe]);
    appendSession(reason);
    persistState();
    WatchUi.requestUpdate();
  }

  function startBreathingSession() as Void {
    _state = STATE_BREATHING;
    _breathingElapsed = 0;
    if (_breathingTimer == null) { _breathingTimer = new Timer.Timer(); }
    _breathingTimer.start(method(:tickBreathing), 1, true);
    WatchUi.requestUpdate();
  }

  function tickBreathing() as Void {
    _breathingElapsed += 1;
    if ((_breathingElapsed % 4) == 0) {
      Attention.vibrate([new Attention.VibeProfile(30, 140)]);
    }

    if (_breathingElapsed >= BREATH_DURATION_SECONDS) {
      if (_breathingTimer != null) { _breathingTimer.stop(); }
      _state = STATE_REFLECTION;
      Application.Storage.setValue(KEY_LAST_SESSION_COMPLETED, true);
      _dailyMetrics["completion_count"] = (_dailyMetrics["completion_count"] as Number) + 1;
      recalculateCalmingRate();
      persistState();
    }

    WatchUi.requestUpdate();
  }

  function skipBreathingSession() as Void {
    if (_breathingTimer != null) { _breathingTimer.stop(); }
    _state = STATE_REFLECTION;
    Application.Storage.setValue(KEY_LAST_SESSION_COMPLETED, false);
    persistState();
    WatchUi.requestUpdate();
  }

  function saveReflection(mood as String, systolic as Number?, diastolic as Number?) as Void {
    if (_sessionLog.size() == 0) {
      _state = STATE_IDLE;
      return;
    }

    var idx = _sessionLog.size() - 1;
    var entry = _sessionLog[idx];
    entry["session_completed"] = getLastSessionCompleted();
    entry["mood_after"] = mood;
    if (systolic != null && diastolic != null) {
      entry["optional_bp"] = { "systolic" => systolic, "diastolic" => diastolic };
    }

    _sessionLog[idx] = entry;
    _state = STATE_SUMMARY;
    persistState();
    WatchUi.requestUpdate();
  }

  function goIdle() as Void {
    _state = STATE_IDLE;
    persistState();
    WatchUi.requestUpdate();
  }

  function appendSession(reason as String) as Void {
    _sessionLog.add({
      "timestamp" => Time.now().value(),
      "trigger_reason" => reason,
      "session_completed" => false,
      "mood_after" => "",
      "optional_bp" => null
    });
  }

  function recalculateCalmingRate() as Void {
    var triggers = _dailyMetrics["trigger_count"] as Number;
    var completions = _dailyMetrics["completion_count"] as Number;
    _dailyMetrics["calming_rate"] = (triggers <= 0) ? 0.0 : (completions.toFloat() / triggers.toFloat()) * 100.0;
  }

  function hasDisclaimerAck() as Boolean { return Application.Storage.getValue(KEY_DISCLAIMER_ACK, false); }

  function loadPersistedState() as Void {
    _baselineHr = Application.Storage.getValue(KEY_BASELINE_HR, 0);
    _lastTriggerAt = Application.Storage.getValue(KEY_LAST_TRIGGER_AT, 0);
    _cooldownMinutes = Application.Storage.getValue(KEY_COOLDOWN_MIN, 45);
    _sessionLog = Application.Storage.getValue(KEY_SESSION_LOG, []);
    _dailyMetrics = Application.Storage.getValue(KEY_DAILY_METRICS, {
      "trigger_count" => 0,
      "completion_count" => 0,
      "calming_rate" => 0.0
    });
  }

  function persistState() as Void {
    Application.Storage.setValue(KEY_BASELINE_HR, _baselineHr);
    Application.Storage.setValue(KEY_LAST_TRIGGER_AT, _lastTriggerAt);
    Application.Storage.setValue(KEY_COOLDOWN_MIN, _cooldownMinutes);
    Application.Storage.setValue(KEY_SESSION_LOG, _sessionLog);
    Application.Storage.setValue(KEY_DAILY_METRICS, _dailyMetrics);
  }
}
