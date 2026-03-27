import QtQuick 2.2
import Sailfish.Silica 1.0

Item {
  id: root
  property var itemData
  property int index
  
  width: parent.width
  height: Theme.itemSizeMedium

  readonly property real iconScale: 0.8
  readonly property int scaledIconSize: Theme.iconSizeMedium * iconScale

  function getActionIcon(type) {
    switch(type) {
      case "command": return "image://theme/icon-m-terminal"
      case "mqtt":   return "../../icons/icon-m-mqtt.svg"
      case "mqtt_publish":   return "../../icons/icon-m-mqtt.svg"
      case "dbus_method":   return "../../icons/icon-m-dbus.svg"
      case "log": return "image://theme/icon-m-document"
      case "write_data": return "image://theme/icon-m-edit"
      case "http":   return "../../icons/icon-m-http.svg"
      case "sqlite_query":   return "../../icons/icon-m-db.svg"
      case "mysql_query":   return "../../icons/icon-m-db.svg"
      case "smtp": return "image://theme/icon-m-mail"
      case "imap_mark_seen": return "image://theme/icon-m-mail"
      case "shell": return "image://theme/icon-m-tab-return"
      default:       return "image://theme/icon-m-play"
    }
  }

  Icon {
    id: tech_icon
    source: getActionIcon(itemData.type)
    width: scaledIconSize
    height: scaledIconSize
    color: Theme.primaryColor
    opacity: 0.6
    rotation: itemData.type == "shell" ? 180 : 0;
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
      text: itemData.name || "Unnamed Action"
      color: Theme.primaryColor
      font.pixelSize: Theme.fontSizeMedium
      truncationMode: TruncationMode.Fade
    }

    Label {
      width: parent.width
      text: (itemData.type ? itemData.type.toUpperCase() : "ACTION") + (itemData.command ? " • " + itemData.command : "")
      font.pixelSize: Theme.fontSizeExtraSmall
      color: Theme.secondaryColor
      opacity: 0.8
      truncationMode: TruncationMode.Fade
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
