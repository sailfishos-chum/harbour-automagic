import QtQuick 2.6
import Sailfish.Silica 1.0
import "pages"

ApplicationWindow {
  id: app

  signal signal_error(string module_id, string method_id, string description)
  signal signal_success(string module_id, string method_id, string description)
  signal signal_settings_changed(var data)
  signal signal_update_data_sources(var data)
  signal signal_update_flows(var data)
  signal signal_update_actions(var data)
  signal signal_update_states(var data)
  signal signal_update_value_maps(var data)
  signal signal_state_changed(string state_name, var data)
  signal signal_log_received(string flow_id, string step_id, string run_id, string message)

  property string version: "0.1"
  
  property var templates
  property var data_sources
  property var flows
  property var actions
  property var value_maps
  property var states
  property var settings
  property bool busy
  property bool connected
  property string dynamic_page: "states"

  PythonHandler {
    id: python
  }

  NotificationsHandler {
    id: notifications_handler
  }

  initialPage: Component { 
    id: initial_page

    MainPage {
      id: main_page
    }
  }
  
  cover: Component { 
    id: cover_component

    CoverPage {
      id: cover_page
    } 
  }

  Component.onCompleted: {
    Qt.application.name = "automagic";
    Qt.application.organization = "app.qml";
  }
}
