import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Application;
import Toybox.Time;
import Toybox.System;
import Toybox.Position;
import Toybox.Math;

class GeofenceView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();

        var dist = Application.Storage.getValue("lastDist");
        var lat = Application.Storage.getValue("lastLat");
        var lon = Application.Storage.getValue("lastLon");
        var active = Application.Storage.getValue("isListeningActive");
        var isActive = (active != null && active == true);

        if (lat == null || lon == null) {
            if (!isActive) {
                dc.setColor(0xFFE6BA, 0xFFE6BA);
            }else{
                dc.setColor(0xC2FFC4, 0xC2FFC4);
            }
        } else {
            dc.setColor(0xEEEEEE, 0xEEEEEE);
        }
        dc.clear();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 38, Graphics.FONT_SMALL, "Geofence", Graphics.TEXT_JUSTIFY_CENTER);

        var buttonY = 73;
        var globalSpacer = 15;
        buttonY+=globalSpacer;
        var buttonHeight = 48;
        var buttonWidth = (width * 0.65).toNumber();
        var buttonX = (width - buttonWidth) / 2;

        if (isActive) {
            dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_DK_RED);
            dc.fillRoundedRectangle(buttonX, buttonY + 6, buttonWidth, buttonHeight, 10);
            
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, buttonY + 10, Graphics.FONT_MEDIUM, "| |", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(0x095700, 0x095700);
            dc.fillRoundedRectangle(buttonX - (buttonX / 6), buttonY + 12, buttonWidth, buttonHeight, 10);            
            dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_DK_GREEN);
            dc.fillRoundedRectangle(buttonX, buttonY + 6, buttonWidth, buttonHeight, 10);

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, buttonY + 10, Graphics.FONT_MEDIUM, "READY", Graphics.TEXT_JUSTIFY_CENTER);
        }

        // dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
        // dc.drawLine(25, 108, width - 25, 108);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        var yPos = buttonY + 44;

        var showCoordsObj = Application.Storage.getValue("showCoords");
        var showCoords = (showCoordsObj != null) ? (showCoordsObj as Boolean) : false;

        if (lat != null && lon != null) {
            if (dist != null) {
                dc.drawText(width / 2, yPos + 20, Graphics.FONT_XTINY, "Dist to Target: " + dist.format("%.1f") + "m", Graphics.TEXT_JUSTIFY_CENTER);
            }
            yPos += 48;

            if (showCoords) {
                dc.drawText(width / 2, yPos, Graphics.FONT_XTINY, "POSITION", Graphics.TEXT_JUSTIFY_CENTER);
                yPos += 18;
                dc.drawText(width / 2, yPos, Graphics.FONT_XTINY, "Lon: " + lon.format("%.5f"), Graphics.TEXT_JUSTIFY_CENTER);
                yPos += 20;
                dc.drawText(width / 2, yPos, Graphics.FONT_XTINY, "Lat: " + lat.format("%.5f"), Graphics.TEXT_JUSTIFY_CENTER);
            } else {
                // Render the clickable "SHOW" toggle state
                dc.setColor(0x005999, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width / 2, yPos, Graphics.FONT_TINY, "[ SHOW POSITION ]", Graphics.TEXT_JUSTIFY_CENTER);
            }
        } else {
            dc.drawText(width / 2, yPos + 22, Graphics.FONT_XTINY, "POSITION HISTORY", Graphics.TEXT_JUSTIFY_CENTER);
            yPos += 24;
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, yPos + 18, Graphics.FONT_XTINY, "n/a", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}

class GeofenceDelegate extends WatchUi.BehaviorDelegate {
    public static var hasTriggeredInSession = false;
    public static var snoozeUntilTime = 0;

    private const TARGET_LAT = GeneratedConfig.TARGET_LAT;
    private const TARGET_LON = GeneratedConfig.TARGET_LON;
    private const RADIUS_METERS = GeneratedConfig.RADIUS_METERS;

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Boolean {
        return false; // Allow standard view popping when desired
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        var coords = evt.getCoordinates();
        var yPos = coords[1];
        
        // Zone 1: Top half / button area
        if (yPos >= 40 && yPos <= 150) {
            return toggleListeningState();
        } 
        
        // Zone 2: Bottom coordinate / POSITION display area
        else if (yPos >= 160 && yPos <= 260) {
            var current = Application.Storage.getValue("showCoords");
            var showCoords = (current == null || current == true);
            
            Application.Storage.setValue("showCoords", !showCoords);
            WatchUi.requestUpdate();
            return true;
        }
        
        return false;
    }

    private function toggleListeningState() as Boolean {
        var active = Application.Storage.getValue("isListeningActive");
        var isActive = (active != null && active == true);

        if (isActive) {
            stopTracking();
        } else {
            Application.Storage.setValue("isListeningActive", true);
            hasTriggeredInSession = false;
            snoozeUntilTime = 0;

            try {
                Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPositionUpdate));
            } catch (e) {}

            System.println("Tracking STARTED.");
        }

        WatchUi.requestUpdate();
        return true;
    }

    public static function stopTracking() as Void {
        Application.Storage.setValue("isListeningActive", false);

        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
        hasTriggeredInSession = false;
        snoozeUntilTime = 0;
        System.println("Tracking STOPPED.");
        WatchUi.requestUpdate();
    }

    function onPositionUpdate(info as Position.Info) as Void {
        if (info != null && info.position != null) {
            var latLon = info.position.toDegrees();
            var lat = latLon[0];
            var lon = latLon[1];
            var currentTime = Time.now().value();

            Application.Storage.setValue("lastLat", lat);
            Application.Storage.setValue("lastLon", lon);
            Application.Storage.setValue("lastTime", currentTime);

            var distance = calculateDistance(lat, lon, TARGET_LAT, TARGET_LON);
            Application.Storage.setValue("lastDist", distance);

            if (distance <= RADIUS_METERS) {
                if (!hasTriggeredInSession && currentTime >= snoozeUntilTime) {
                    hasTriggeredInSession = true;
                    System.println("Inside boundary! Opening target selection menu...");
                    openTargetMenu();
                }
            } else {
                hasTriggeredInSession = false;
            }

            WatchUi.requestUpdate();
        }
    }

    private function calculateDistance(lat1 as Double, lon1 as Double, lat2 as Double, lon2 as Double) as Float {
        var radLat1 = Math.toRadians(lat1);
        var radLat2 = Math.toRadians(lat2);
        var deltaLat = Math.toRadians(lat2 - lat1);
        var deltaLon = Math.toRadians(lon2 - lon1);

        var a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
                Math.cos(radLat1) * Math.cos(radLat2) *
                Math.sin(deltaLon / 2) * Math.sin(deltaLon / 2);
                
        var c = 2.0 * Math.atan2(Math.sqrt(a), Math.sqrt(1.0 - a));
        return (6371000.0 * c).toFloat();
    }

    function onMenu() as Boolean {
        openTargetMenu();
        return true;
    }

    private function openTargetMenu() as Void {
        var menu = new WatchUi.Menu2({:title => "Remote Actions"});
        
        // Dynamically populate custom actions from config.json via GeneratedConfig
        GeneratedConfig.populateMenu(menu);

        // Add static utility actions at the bottom
        menu.addItem(new WatchUi.MenuItem("Snooze 10 min", "Mute alerts temporarily", :snooze, null));
        menu.addItem(new WatchUi.MenuItem("Stop Activity", "End tracking session", :stop, null));
        
        WatchUi.pushView(menu, new TargetMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
    }
}