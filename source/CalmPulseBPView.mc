using Toybox.Graphics;
using Toybox.WatchUi;

class CalmPulseBPView extends WatchUi.View {
  var _app;

  function initialize(app) {
    View.initialize();
    _app = app;
  }

  function onUpdate(dc as Dc) as Void {
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    dc.clear();

    var snapshot = _app.getUiSnapshot();
    var state = snapshot["state"] as String;

    drawTitle(dc, "CalmPulse BP");

    if (state == "Onboarding") {
      drawOnboarding(dc);
    } else if (state == "Idle") {
      drawIdle(dc, snapshot);
    } else if (state == "Triggered") {
      drawTriggered(dc);
    } else if (state == "BreathingActive") {
      drawBreathing(dc, snapshot);
    } else if (state == "ReflectionPending") {
      drawReflection(dc);
    } else {
      drawSummary(dc, snapshot);
    }
  }

  function drawTitle(dc, title as String) as Void {
    dc.drawText(dc.getWidth() / 2, 12, Graphics.FONT_SMALL, title, Graphics.TEXT_JUSTIFY_CENTER);
  }

  function drawOnboarding(dc) as Void {
    dc.drawText(8, 40, Graphics.FONT_XTINY, "Bukan alat diagnosis.", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 56, Graphics.FONT_XTINY, "Gunakan untuk jeda sadar.", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 88, Graphics.FONT_XTINY, "START: setuju + baseline", Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawIdle(dc, snapshot as Dictionary) as Void {
    var baseline = snapshot["baseline_hr"] as Number;
    dc.drawText(8, 44, Graphics.FONT_SMALL, "Mode Siaga", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 68, Graphics.FONT_XTINY, "Baseline HR: " + baseline.format("%d"), Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 94, Graphics.FONT_XTINY, "UP: ringkasan", Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawTriggered(dc) as Void {
    dc.drawText(8, 44, Graphics.FONT_MEDIUM, "Waktunya Jeda", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 74, Graphics.FONT_XTINY, "START: napas 60 dtk", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 90, Graphics.FONT_XTINY, "BACK: batal", Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawBreathing(dc, snapshot as Dictionary) as Void {
    var remain = snapshot["breathing_remaining"] as Number;
    dc.drawText(8, 44, Graphics.FONT_SMALL, "Tarik - hembus pelan", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 72, Graphics.FONT_NUMBER_MEDIUM, remain.format("%d"), Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 100, Graphics.FONT_XTINY, "BACK: lewati sesi", Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawReflection(dc) as Void {
    dc.drawText(8, 40, Graphics.FONT_SMALL, "Setelah sesi?", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 64, Graphics.FONT_XTINY, "START: lebih tenang", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 80, Graphics.FONT_XTINY, "UP: masih tegang", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 96, Graphics.FONT_XTINY, "DOWN: lewati", Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawSummary(dc, snapshot as Dictionary) as Void {
    var metrics = snapshot["daily_metrics"] as Dictionary;
    var triggers = metrics["trigger_count"] as Number;
    var completions = metrics["completion_count"] as Number;
    var rate = metrics["calming_rate"] as Float;

    dc.drawText(8, 36, Graphics.FONT_SMALL, "Ringkasan Hari Ini", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 58, Graphics.FONT_XTINY, "Trigger: " + triggers.format("%d"), Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 74, Graphics.FONT_XTINY, "Sesi selesai: " + completions.format("%d"), Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 90, Graphics.FONT_XTINY, "Calming: " + rate.format("%.0f") + "%", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 108, Graphics.FONT_XTINY, "BACK: kembali", Graphics.TEXT_JUSTIFY_LEFT);
  }
}
