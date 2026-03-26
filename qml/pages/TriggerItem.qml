import QtQuick 2.2
import Sailfish.Silica 1.0

Item {
  id: root
  property var itemData
  property int index
  
  width: parent.width
  height: Theme.itemSizeMedium

  readonly property bool isEnabled: itemData.enabled !== undefined ? itemData.enabled : true
  readonly property real iconScale: 0.8
  readonly property int scaledIconSize: Theme.iconSizeMedium * iconScale

  function getTriggerIcon(type) {
    switch(type) {
      case "timer":  return "image://theme/icon-m-alarm"
      case "mqtt":   return "../../icons/icon-m-mqtt.svg"
      case "http":   return "../../icons/icon-m-http.svg"
      case "dbus":   return "../../icons/icon-m-dbus.svg"
      case "file":   return "image://theme/icon-m-file-folder"
      case "state":  return "../../icons/icon-m-flow.svg"
      case "sqlite": return "../../icons/icon-m-db.svg"
      case "mysql":  return "../../icons/icon-m-db.svg"
      default:       return "image://theme/icon-m-enter-accept"
    }
  }

  function getMetadataText() {
    var typeStr = itemData.type ? itemData.type.toUpperCase() : "TRIGGER"
    if (itemData.type === "timer" && itemData.interval) return typeStr + " • Every " + itemData.interval
    if (itemData.topic) return typeStr + " • " + itemData.topic
    return typeStr
  }

  Rectangle {
    id: strip
    anchors.left: parent.left
    width: Theme.paddingSmall / 2
    height: parent.height - Theme.paddingLarge
    anchors.verticalCenter: parent.verticalCenter
    color: isEnabled ? Theme.highlightColor : Theme.secondaryColor
    radius: Theme.paddingSmall
  }

  Item {
    anchors {
      left: strip.right
      right: parent.right
      top: parent.top
      bottom: parent.bottom
    }
    opacity: isEnabled ? 1.0 : 0.4

    Icon {
      id: tech_icon
      source: getTriggerIcon(itemData.type)
      width: scaledIconSize
      height: scaledIconSize
      color: Theme.primaryColor
      opacity: 0.7
      anchors {
        left: parent.left
        leftMargin: Theme.paddingSmall
        verticalCenter: parent.verticalCenter
      }
    }

    Column {
      anchors {
        left: tech_icon.right
        leftMargin: Theme.paddingSmall
        right: parent.right
        rightMargin: Theme.horizontalPageMargin
        verticalCenter: parent.verticalCenter
      }

      Label {
        width: parent.width
        text: itemData.name || "Unnamed Trigger"
        color: Theme.primaryColor
        font.pixelSize: Theme.fontSizeMedium
        truncationMode: TruncationMode.Fade
      }

      Label {
        width: parent.width
        text: getMetadataText()
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
        opacity: 0.8
        truncationMode: TruncationMode.Fade
      }
    }
  }

  Separator {
    anchors.top: parent.top
    width: parent.width
    color: Theme.primaryColor
    opacity: 0.8
    visible: index === 0 
  }

  Separator {
    anchors.bottom: parent.bottom
    width: parent.width
    color: Theme.primaryColor
    opacity: 0.8
  }
}
