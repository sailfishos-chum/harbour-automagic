import QtQuick 2.2
import Sailfish.Silica 1.0

Item {
  id: root
  property var itemData
  property string displayTriggerName
  property int index

  width: parent.width
  height: Theme.itemSizeMedium

  readonly property bool isEnabled: itemData.enabled !== undefined ? itemData.enabled : true
  readonly property real iconScale: 0.8
  readonly property int scaledIconSize: Theme.iconSizeMedium * iconScale

  Item {
    anchors.fill: parent
    opacity: isEnabled ? 1.0 : 0.4

    Icon {
      id: tech_icon
      source: "../../icons/icon-m-flow.svg"
      width: scaledIconSize
      height: scaledIconSize
      color: Theme.primaryColor
      opacity: 0.6
      anchors {
        left: parent.left
        leftMargin: Theme.paddingSmall
        verticalCenter: parent.verticalCenter
      }
    }

    Column {
      anchors {
        left: tech_icon.right
        leftMargin: Theme.paddingMedium
        right: parent.right
        rightMargin: Theme.horizontalPageMargin
        verticalCenter: parent.verticalCenter
      }
      spacing: 0

      Label {
        width: parent.width
        text: itemData.name || "Unnamed Flow"
        color: Theme.primaryColor
        font.pixelSize: Theme.fontSizeMedium
        truncationMode: TruncationMode.Fade
      }

      Label {
        width: parent.width
        text: displayTriggerName !== "" ? displayTriggerName : "No Trigger Attached"
        font.pixelSize: Theme.fontSizeExtraSmall
        color: displayTriggerName !== "" ? Theme.secondaryColor : Theme.errorColor
        truncationMode: TruncationMode.Fade
        opacity: 0.8
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
