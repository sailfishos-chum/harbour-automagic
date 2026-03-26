import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
  id: settings_dialog

  property string selectedMode: "states"
  property string startupTab: "1"
  property int logLimit: 100

  SilicaFlickable {
    anchors.fill: parent
    contentHeight: column.height + Theme.paddingLarge

    Column {
      id: column
      width: parent.width

      DialogHeader {
        title: "Settings"
      }

      ComboBox {
        id: view_combo
        width: parent.width
        label: "Dynamic Tab View"
        
        menu: ContextMenu {
          MenuItem {
            text: "States"
            onClicked: selectedMode = "states"
          }
          MenuItem {
            text: "Log"
            onClicked: selectedMode = "logs"
          }
        }
      }

      ComboBox {
        id: startup_combo
        width: parent.width
        label: "Startup Tab"
        
        menu: ContextMenu {
          MenuItem {
            text: "Sources"
            onClicked: startupTab = "0"
          }
          MenuItem {
            text: "Flows"
            onClicked: startupTab = "1"
          }
          MenuItem {
            text: "Actions"
            onClicked: startupTab = "2"
          }
          MenuItem {
            text: "States / Log"
            onClicked: startupTab = "3"
          }
        }
      }

      Slider {
        id: log_slider
        width: parent.width
        label: "Log History Limit"
        minimumValue: 50
        maximumValue: 1000
        stepSize: 50
        value: logLimit
        valueText: value + " lines"
        onValueChanged: logLimit = value
      }
    }
  }

  Component.onCompleted: {
    var s = app.settings || {}
    
    selectedMode = s.dynamic_page || app.dynamic_page || "states"
    view_combo.currentIndex = selectedMode === "logs" ? 1 : 0

    startupTab = s.startup_tab || "1"
    startup_combo.currentIndex = parseInt(startupTab)
    
    if (s.log_limit !== undefined) {
      logLimit = s.log_limit
    }
  }

  onAccepted: {
    var s = app.settings || {}
    
    s.dynamic_page = selectedMode
    s.startup_tab = startupTab
    s.log_limit = logLimit

    app.settings = s
    app.dynamic_page = selectedMode
    
    python.save_settings()
  }
}
