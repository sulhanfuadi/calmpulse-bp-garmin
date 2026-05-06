class StateMachine {
  const STATE_ONBOARDING = "Onboarding";
  const STATE_IDLE = "Idle";
  const STATE_TRIGGERED = "Triggered";
  const STATE_BREATHING = "BreathingActive";
  const STATE_REFLECTION = "ReflectionPending";
  const STATE_SUMMARY = "Summary";

  var _state;

  function initialize() {
    _state = STATE_ONBOARDING;
  }

  function getState() as String {
    return _state;
  }

  function setStateForRecovery() as Void {
    _state = STATE_IDLE;
  }

  function transition(next as String) as Boolean {
    if (_state == next) {
      return true;
    }

    if (isAllowed(_state, next)) {
      _state = next;
      return true;
    }

    return false;
  }

  function isAllowed(current as String, next as String) as Boolean {
    if (current == STATE_ONBOARDING) {
      return next == STATE_IDLE;
    }

    if (current == STATE_IDLE) {
      return next == STATE_TRIGGERED || next == STATE_SUMMARY;
    }

    if (current == STATE_TRIGGERED) {
      return next == STATE_BREATHING || next == STATE_IDLE;
    }

    if (current == STATE_BREATHING) {
      return next == STATE_REFLECTION;
    }

    if (current == STATE_REFLECTION) {
      return next == STATE_SUMMARY || next == STATE_IDLE;
    }

    if (current == STATE_SUMMARY) {
      return next == STATE_IDLE;
    }

    return false;
  }
}
