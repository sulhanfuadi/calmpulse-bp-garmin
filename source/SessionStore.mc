using Toybox.Application;
using Toybox.System;
using Toybox.Time;

class SessionStore {
  const KEY_BASELINE_HR = "baseline_hr";
  const KEY_LAST_TRIGGER_AT = "last_trigger_at";
  const KEY_COOLDOWN_MIN = "cooldown_minutes";
  const KEY_SESSION_LOG = "session_log";
  const KEY_DAILY_METRICS = "daily_metrics";
  const KEY_DISCLAIMER_ACK = "disclaimer_ack";
  const KEY_LAST_SESSION_COMPLETED = "last_session_completed";
  const KEY_METRICS_DAY = "metrics_day";

  function initialize() {}

  function loadState() as Dictionary {
    var state = {
      "baseline_hr" => safeGet(KEY_BASELINE_HR, AppConfig.DEFAULT_BASELINE_HR),
      "last_trigger_at" => safeGet(KEY_LAST_TRIGGER_AT, 0),
      "cooldown_minutes" => safeGet(KEY_COOLDOWN_MIN, AppConfig.DEFAULT_COOLDOWN_MINUTES),
      "session_log" => safeGet(KEY_SESSION_LOG, []),
      "daily_metrics" => safeGet(KEY_DAILY_METRICS, defaultMetrics()),
      "disclaimer_ack" => safeGet(KEY_DISCLAIMER_ACK, false),
      "last_session_completed" => safeGet(KEY_LAST_SESSION_COMPLETED, false),
      "metrics_day" => safeGet(KEY_METRICS_DAY, currentDayKey())
    };

    sanitizeState(state);
    return state;
  }

  function persistState(state as Dictionary) as Void {
    safeSet(KEY_BASELINE_HR, state["baseline_hr"]);
    safeSet(KEY_LAST_TRIGGER_AT, state["last_trigger_at"]);
    safeSet(KEY_COOLDOWN_MIN, state["cooldown_minutes"]);
    safeSet(KEY_SESSION_LOG, state["session_log"]);
    safeSet(KEY_DAILY_METRICS, state["daily_metrics"]);
    safeSet(KEY_DISCLAIMER_ACK, state["disclaimer_ack"]);
    safeSet(KEY_LAST_SESSION_COMPLETED, state["last_session_completed"]);
    safeSet(KEY_METRICS_DAY, state["metrics_day"]);
  }

  function rollDailyMetricsIfNeeded(state as Dictionary) as Void {
    var today = currentDayKey();
    var storedDay = state["metrics_day"];
    if (storedDay == null || storedDay != today) {
      state["daily_metrics"] = defaultMetrics();
      state["metrics_day"] = today;
    }
  }

  function currentDayKey() as String {
    var moment = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    return moment.year.format("%04d") + "-" + moment.month.format("%02d") + "-" + moment.day.format("%02d");
  }

  function defaultMetrics() as Dictionary {
    return {
      "trigger_count" => 0,
      "completion_count" => 0,
      "calming_rate" => 0.0
    };
  }

  function sanitizeState(state as Dictionary) as Void {
    if (!(state["baseline_hr"] instanceof Number) || (state["baseline_hr"] as Number) <= 0) {
      state["baseline_hr"] = AppConfig.DEFAULT_BASELINE_HR;
    }

    if (!(state["last_trigger_at"] instanceof Number) || (state["last_trigger_at"] as Number) < 0) {
      state["last_trigger_at"] = 0;
    }

    if (!(state["cooldown_minutes"] instanceof Number) || (state["cooldown_minutes"] as Number) <= 0) {
      state["cooldown_minutes"] = AppConfig.DEFAULT_COOLDOWN_MINUTES;
    }

    if (!(state["session_log"] instanceof Array)) {
      state["session_log"] = [];
    }

    if (!(state["daily_metrics"] instanceof Dictionary)) {
      state["daily_metrics"] = defaultMetrics();
    } else {
      var metrics = state["daily_metrics"] as Dictionary;
      if (!(metrics["trigger_count"] instanceof Number)) { metrics["trigger_count"] = 0; }
      if (!(metrics["completion_count"] instanceof Number)) { metrics["completion_count"] = 0; }
      if (!(metrics["calming_rate"] instanceof Float) && !(metrics["calming_rate"] instanceof Number)) { metrics["calming_rate"] = 0.0; }
    }

    if (!(state["disclaimer_ack"] instanceof Boolean)) {
      state["disclaimer_ack"] = false;
    }

    if (!(state["last_session_completed"] instanceof Boolean)) {
      state["last_session_completed"] = false;
    }

    if (!(state["metrics_day"] instanceof String)) {
      state["metrics_day"] = currentDayKey();
    }
  }

  function safeGet(key as String, fallback) {
    try {
      return Application.Storage.getValue(key, fallback);
    } catch(e) {
      System.println("Storage read fallback: " + key);
      return fallback;
    }
  }

  function safeSet(key as String, value) as Void {
    try {
      Application.Storage.setValue(key, value);
    } catch(e) {
      System.println("Storage write skipped: " + key);
    }
  }
}
