import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Background;
import Toybox.Time;
import Toybox.System;
import Toybox.Communications;
import Toybox.Timer;

class GeofenceApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new GeofenceView(), new GeofenceDelegate() ];
    }

    function getServiceDelegate() as [System.ServiceDelegate] {
        return [ new GeofenceServiceDelegate() ];
    }
}

(:background)
class GeofenceServiceDelegate extends System.ServiceDelegate {
    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        Background.exit(null);
    }
}

class TargetMenuDelegate extends WatchUi.Menu2InputDelegate {
    private static var isSending = false;
    private var dismissTimer as Timer.Timer?;
    private var selectedItem as WatchUi.MenuItem?;

    function initialize() {
        Menu2InputDelegate.initialize();
        dismissTimer = new Timer.Timer();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        if (isSending) {
            return;
        }

        var id = item.getId() as Symbol;
        if (id == :snooze) {
            GeofenceDelegate.snoozeUntilTime = Time.now().value() + 600;
            System.println("Tracking snoozed for 10 minutes.");
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return;
        } else if (id == :stop) {
            GeofenceDelegate.stopTracking();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return;
        }

        // MINIMAL CHANGE: Dynamically fetch payload from GeneratedConfig
        var payload = GeneratedConfig.getPayload(id);
        if (payload != null && !payload.equals("")) {
            selectedItem = item;
            System.println("Selected: " + item.getLabel());
            sendTopicRequest(payload, item);
        }
    }

    function onBack() as Void {
        if (!isSending) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
    }

    private function sendTopicRequest(secretPayload as String, item as WatchUi.MenuItem) as Void {
        isSending = true;
        item.setSubLabel("Sending...");
        WatchUi.requestUpdate();

        // MINIMAL CHANGE: Use GeneratedConfig URL instead of hardcoded string
        var webhookUrl = GeneratedConfig.WEBHOOK_URL;

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => { 
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
            }
        };

        Communications.makeWebRequest(
            webhookUrl,
            { "message" => secretPayload },
            options,
            method(:onReceiveWebResponse)
        );
    }

    function onReceiveWebResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        System.println("Webhook HTTP Response Code: " + responseCode);
        
        if (selectedItem != null) {
            if (responseCode == 200) {
                selectedItem.setSubLabel("Success!");
                WatchUi.requestUpdate();
                
                if (dismissTimer != null) {
                    dismissTimer.start(method(:dismissMenu), 1500, false);
                }
                return;
            } else {
                selectedItem.setSubLabel("Failed (Code " + responseCode + ")");
            }
        }
        
        isSending = false;
        WatchUi.requestUpdate();
    }

    function dismissMenu() as Void {
        isSending = false;
        try {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } catch (e) {}
    }
}