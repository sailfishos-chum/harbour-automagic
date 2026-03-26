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

  function formatType(type) {
    if (!type) return "FILE"
    return type.toUpperCase()
  }

  function getSourceIcon(type) {
    switch(type) {
      case "timer":  return "image://theme/icon-m-alarm"
      case "mqtt":   return "../../icons/icon-m-mqtt.svg"
      case "http":   return "../../icons/icon-m-http.svg"
      case "dbus":   return "../../icons/icon-m-dbus.svg"
      case "file":   return "image://theme/icon-m-file-folder"
      case "state":  return "../../icons/icon-m-flow.svg"
      case "sqlite": return "../../icons/icon-m-db.svg"
      case "mysql":  return "../../icons/icon-m-db.svg"
      case "imap":   return "image://theme/icon-m-mail"
      default:       return "image://theme/icon-m-diagnostic"
    }
  }

  Item {
    anchors.fill: parent
    opacity: isEnabled ? 1.0 : 0.4

    Icon {
      id: tech_icon
      source: getSourceIcon(itemData.type)
      width: scaledIconSize
      height: scaledIconSize
      color: Theme.primaryColor
      opacity: 0.6
      anchors {
        left: parent.left
        leftMargin: Theme.paddingMedium
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
        text: itemData.name || "Unnamed Source"
        color: Theme.primaryColor
        font.pixelSize: Theme.fontSizeMedium
        truncationMode: TruncationMode.Fade
      }

      Label {
        width: parent.width
        text: formatType(itemData.type) + (itemData.topic ? " • " + itemData.topic : "")
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
