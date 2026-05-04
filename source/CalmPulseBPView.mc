using Toybox.Graphics;
using Toybox.Lang;
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

    var state = _app.getState();
    drawTitle(dc, "CalmPulse BP");

    if (state == "Onboarding") {
      drawOnboarding(dc);
    } else if (state == "Idle") {
      drawIdle(dc);
    } else if (state == "Triggered") {
      drawTriggered(dc);
    } else if (state == "BreathingActive") {
      drawBreathing(dc);
    } else if (state == "ReflectionPending") {
      drawReflection(dc);
    } else {
      drawSummary(dc);
    }
  }

  function drawTitle(dc, title as String) as Void {
    dc.drawText(dc.getWidth() / 2, 12, Graphics.FONT_SMALL, title, Graphics.TEXT_JUSTIFY_CENTER);
  }

  function drawOnboarding(dc) as Void {
    dc.drawText(8, 42, Graphics.FONT_XTINY, "Ini bukan alat diagnosis.", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 58, Graphics.FONT_XTINY, "Gunakan sebagai self-awareness.", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 90, Graphics.FONT_XTINY, "START: set baseline + setuju", Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawIdle(dc) as Void {
    var baseline = _app.getBaselineHr();
    dc.drawText(8, 46, Graphics.FONT_SMALL, "Mode: Idle", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 70, Graphics.FONT_XTINY, "Baseline HR: " + baseline.format("%d"), Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 96, Graphics.FONT_XTINY, "UP: lihat summary", Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawTriggered(dc) as Void {
    dc.drawText(8, 46, Graphics.FONT_MEDIUM, "Perlu jeda", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 76, Graphics.FONT_XTINY, "START: breathing 60s", Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawBreathing(dc) as Void {
    var elapsed = _app.getBreathingElapsed();
    var remain = 60 - elapsed;
    if (remain < 0) { remain = 0; }

    dc.drawText(8, 46, Graphics.FONT_SMALL, "Tarik - hembus pelan", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 74, Graphics.FONT_NUMBER_MEDIUM, remain.format("%d"), Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 102, Graphics.FONT_XTINY, "BACK: lewati sesi", Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawReflection(dc) as Void {
    dc.drawText(8, 42, Graphics.FONT_SMALL, "Setelah sesi?", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 66, Graphics.FONT_XTINY, "START: lebih tenang", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 82, Graphics.FONT_XTINY, "UP: masih tegang", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 98, Graphics.FONT_XTINY, "DOWN: lewati", Graphics.TEXT_JUSTIFY_LEFT);
  }

  function drawSummary(dc) as Void {
    var metrics = _app.getDailyMetrics();
    var triggers = metrics["trigger_count"] as Number;
    var completions = metrics["completion_count"] as Number;
    var rate = metrics["calming_rate"] as Float;

    dc.drawText(8, 38, Graphics.FONT_SMALL, "Ringkasan Hari Ini", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 60, Graphics.FONT_XTINY, "Trigger: " + triggers.format("%d"), Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 76, Graphics.FONT_XTINY, "Sesi selesai: " + completions.format("%d"), Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 92, Graphics.FONT_XTINY, "Calming rate: " + rate.format("%.0f") + "%", Graphics.TEXT_JUSTIFY_LEFT);
    dc.drawText(8, 110, Graphics.FONT_XTINY, "BACK: kembali idle", Graphics.TEXT_JUSTIFY_LEFT);
  }
}
