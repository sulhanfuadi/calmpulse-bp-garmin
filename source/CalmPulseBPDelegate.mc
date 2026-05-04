using Toybox.WatchUi;

class CalmPulseBPDelegate extends WatchUi.InputDelegate {
  var _app;

  function initialize(app) {
    InputDelegate.initialize();
    _app = app;
  }

  function onKey(key as Key, state as KeyState) as Boolean {
    if (state != WatchUi.KEY_PRESSED) { return false; }

    var appState = _app.getState();

    if (appState == "Onboarding" && key == WatchUi.KEY_START) {
      _app.acknowledgeDisclaimerAndSetBaseline();
      return true;
    }

    if (appState == "Triggered" && key == WatchUi.KEY_START) {
      _app.startBreathingSession();
      return true;
    }

    if (appState == "BreathingActive" && key == WatchUi.KEY_BACK) {
      _app.skipBreathingSession();
      return true;
    }

    if (appState == "ReflectionPending") {
      if (key == WatchUi.KEY_START) { _app.saveReflection("lebih_tenang", null, null); return true; }
      if (key == WatchUi.KEY_UP) { _app.saveReflection("masih_tegang", null, null); return true; }
      if (key == WatchUi.KEY_DOWN) { _app.saveReflection("lewati", null, null); return true; }
    }

    if (appState == "Idle" && key == WatchUi.KEY_UP) {
      _app.openSummary();
      return true;
    }

    if (appState == "Summary" && key == WatchUi.KEY_BACK) {
      _app.goIdle();
      return true;
    }

    return false;
  }
}
