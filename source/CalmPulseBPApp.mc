using Toybox.Application;
using Toybox.Attention;
using Toybox.HeartRate;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.Timer;
using Toybox.WatchUi;

class CalmPulseBPApp extends Application.AppBase {
  var _stateMachine;
  var _triggerEngine;
  var _sessionStore;
  var _breathingController;

  var _runtime;
  var _monitorTimer;

  function initialize() {
    AppBase.initialize();
    _stateMachine = new StateMachine();
    _triggerEngine = new TriggerEngine();
    _sessionStore = new SessionStore();
    _breathingController = new BreathingController();

    _runtime = {
      "baseline_hr" => AppConfig.DEFAULT_BASELINE_HR,
      "last_trigger_at" => 0,
      "cooldown_minutes" => AppConfig.DEFAULT_COOLDOWN_MINUTES,
      "session_log" => [],
      "daily_metrics" => _sessionStore.defaultMetrics(),
      "disclaimer_ack" => false,
      "last_session_completed" => false,
      "metrics_day" => _sessionStore.currentDayKey()
    };
  }

  function onStart(state as Dictionary?) as Void {
    _runtime = _sessionStore.loadState();
    _sessionStore.rollDailyMetricsIfNeeded(_runtime);

    if (!isDisclaimerAck()) {
      _stateMachine.transition(StateMachine.STATE_ONBOARDING);
      stopMonitoring();
      _breathingController.stop();
      WatchUi.requestUpdate();
      return;
    }

    ensureIdleRecovery();
    startMonitoring();
    WatchUi.requestUpdate();
  }

  function onStop(state as Dictionary?) as Void {
    stopMonitoring();
    _breathingController.stop();
    _sessionStore.persistState(_runtime);
  }

  function getInitialView() as [Views] or [Views, InputDelegates] {
    return [ new CalmPulseBPView(self), new CalmPulseBPDelegate(self) ];
  }

  function getState() as String {
    return _stateMachine.getState();
  }

  function getUiSnapshot() as Dictionary {
    return {
      "state" => _stateMachine.getState(),
      "baseline_hr" => _runtime["baseline_hr"],
      "daily_metrics" => _runtime["daily_metrics"],
      "breathing_elapsed" => _breathingController.elapsed(),
      "breathing_remaining" => max(0, AppConfig.BREATH_DURATION_SECONDS - _breathingController.elapsed()),
      "last_session_completed" => _runtime["last_session_completed"]
    };
  }

  function acknowledgeDisclaimerAndSetBaseline() as Void {
    if (_stateMachine.getState() != StateMachine.STATE_ONBOARDING) { return; }

    var sample = HeartRate.getCurrentHeartRate();
    var value = (sample != null && sample > 0) ? sample : AppConfig.DEFAULT_BASELINE_HR;

    _runtime["baseline_hr"] = value;
    _runtime["disclaimer_ack"] = true;
    _stateMachine.transition(StateMachine.STATE_IDLE);

    _sessionStore.persistState(_runtime);
    startMonitoring();
    WatchUi.requestUpdate();
  }

  function openSummary() as Void {
    if (_stateMachine.getState() != StateMachine.STATE_IDLE) { return; }
    if (_stateMachine.transition(StateMachine.STATE_SUMMARY)) {
      WatchUi.requestUpdate();
    }
  }

  function evaluateTrigger() as Void {
    if (_stateMachine.getState() != StateMachine.STATE_IDLE) {
      return;
    }

    var gate = {
      "baseline_hr" => _runtime["baseline_hr"],
      "last_trigger_at" => _runtime["last_trigger_at"],
      "cooldown_minutes" => _runtime["cooldown_minutes"],
      "now_seconds" => Time.now().value()
    };

    if (_triggerEngine.shouldTrigger(gate)) {
      markTriggered("hr_above_baseline_and_inactive");
    }
  }

  function markTriggered(reason as String) as Void {
    if (!_stateMachine.transition(StateMachine.STATE_TRIGGERED)) {
      return;
    }

    _runtime["last_trigger_at"] = Time.now().value();

    var metrics = _runtime["daily_metrics"] as Dictionary;
    metrics["trigger_count"] = (metrics["trigger_count"] as Number) + 1;

    Attention.vibrate([
      new Attention.VibeProfile(AppConfig.VIBE_TRIGGER_INTENSITY, AppConfig.VIBE_TRIGGER_DURATION_MS),
      new Attention.VibeProfile(AppConfig.VIBE_TRIGGER_INTENSITY, AppConfig.VIBE_TRIGGER_DURATION_MS)
    ]);

    appendSession(reason);
    recalculateCalmingRate();
    _sessionStore.persistState(_runtime);
    WatchUi.requestUpdate();
  }

  function startBreathingSession() as Void {
    if (_stateMachine.getState() != StateMachine.STATE_TRIGGERED) { return; }
    if (!_stateMachine.transition(StateMachine.STATE_BREATHING)) { return; }

    _breathingController.start(method(:tickBreathing));
    WatchUi.requestUpdate();
  }

  function tickBreathing() as Void {
    if (_stateMachine.getState() != StateMachine.STATE_BREATHING || !_breathingController.isActive()) {
      _breathingController.stop();
      return;
    }

    _breathingController.tick();

    if (_breathingController.isDone()) {
      _breathingController.stop();
      _breathingController.completeHaptic();
      _runtime["last_session_completed"] = true;
      var metrics = _runtime["daily_metrics"] as Dictionary;
      metrics["completion_count"] = (metrics["completion_count"] as Number) + 1;
      recalculateCalmingRate();
      _stateMachine.transition(StateMachine.STATE_REFLECTION);
      _sessionStore.persistState(_runtime);
    }

    WatchUi.requestUpdate();
  }

  function skipBreathingSession() as Void {
    if (_stateMachine.getState() != StateMachine.STATE_BREATHING) { return; }

    _breathingController.stop();
    _runtime["last_session_completed"] = false;
    _stateMachine.transition(StateMachine.STATE_REFLECTION);
    recalculateCalmingRate();
    _sessionStore.persistState(_runtime);
    WatchUi.requestUpdate();
  }

  function saveReflection(mood as String, systolic as Number?, diastolic as Number?) as Void {
    if (_stateMachine.getState() != StateMachine.STATE_REFLECTION) {
      ensureIdleRecovery();
      WatchUi.requestUpdate();
      return;
    }

    var logs = _runtime["session_log"] as Array;
    if (logs.size() == 0) {
      ensureIdleRecovery();
      WatchUi.requestUpdate();
      return;
    }

    var idx = logs.size() - 1;
    var entry = logs[idx] as Dictionary;
    entry["session_completed"] = _runtime["last_session_completed"];
    entry["mood_after"] = mood;
    entry["optional_bp"] = null;

    logs[idx] = entry;

    _stateMachine.transition(StateMachine.STATE_SUMMARY);
    _sessionStore.persistState(_runtime);
    WatchUi.requestUpdate();
  }

  function goIdle() as Void {
    _breathingController.stop();
    _stateMachine.transition(StateMachine.STATE_IDLE);
    _sessionStore.rollDailyMetricsIfNeeded(_runtime);
    recalculateCalmingRate();
    _sessionStore.persistState(_runtime);
    startMonitoring();
    WatchUi.requestUpdate();
  }

  function appendSession(reason as String) as Void {
    var logs = _runtime["session_log"] as Array;
    logs.add({
      "timestamp" => Time.now().value(),
      "trigger_reason" => reason,
      "session_completed" => false,
      "mood_after" => "",
      "optional_bp" => null
    });
  }

  function recalculateCalmingRate() as Void {
    var metrics = _runtime["daily_metrics"] as Dictionary;
    var triggers = metrics["trigger_count"] as Number;
    var completions = metrics["completion_count"] as Number;
    metrics["calming_rate"] = (triggers <= 0) ? 0.0 : (completions.toFloat() / triggers.toFloat()) * 100.0;
  }

  function ensureIdleRecovery() as Void {
    if (_runtime["baseline_hr"] == null || (_runtime["baseline_hr"] as Number) <= 0) {
      _runtime["baseline_hr"] = AppConfig.DEFAULT_BASELINE_HR;
    }

    _stateMachine.setStateForRecovery();
    _sessionStore.rollDailyMetricsIfNeeded(_runtime);
  }

  function startMonitoring() as Void {
    if (_monitorTimer == null) {
      _monitorTimer = new Timer.Timer();
    }

    _monitorTimer.stop();
    _monitorTimer.start(method(:evaluateTrigger), AppConfig.MONITOR_TICK_SECONDS, true);
  }

  function stopMonitoring() as Void {
    if (_monitorTimer != null) {
      _monitorTimer.stop();
    }
  }

  function isDisclaimerAck() as Boolean {
    return _runtime["disclaimer_ack"];
  }
}
