import QtQuick 2.2
import Sailfish.Silica 1.0

StepBase {
  id: stepBaseThrottle
  stepType: "throttle"
  
  property var paramsArray: []

  Column {
    width: parent.width
    spacing: 0

    BackgroundItem {
      width: parent.width
      height: Theme.itemSizeMedium
      onClicked: stepBaseThrottle.editParamsRequested("step_types", "throttle")

      Column {
        anchors.centerIn: parent
        spacing: Theme.paddingSmall

        Label {
          id: durationLabel
          anchors.horizontalCenter: parent.horizontalCenter
          font.pixelSize: Theme.fontSizeMedium
          color: Theme.secondaryColor
          font.bold: true
          text: {
            if (!paramsArray || paramsArray.length === 0) return ""
            for (var i = 0; i < paramsArray.length; i++) {
              if (paramsArray[i].key === "duration") return paramsArray[i].value
            }
            return ""
          }
        }

        Label {
          anchors.horizontalCenter: parent.horizontalCenter
          text: {
            if (!paramsArray || paramsArray.length === 0) return ""
            for (var i = 0; i < paramsArray.length; i++) {
              if (paramsArray[i].key === "scope" && Array.isArray(paramsArray[i].value)) return paramsArray[i].value.join(", ")
            }
            return ""
          }
          font.pixelSize: Theme.fontSizeSmall
          font.bold: false
          color: Theme.primaryColor
        }
      }

      Icon {
        id: forward_if_icon
        source: "../../icons/arrow_forward.svg"
        height: 40
        width: height
        anchors {
          verticalCenter: parent.verticalCenter
          right: parent.right
          rightMargin: Theme.paddingSmall
        }
      }
    }
  }

  Component.onCompleted: {
    
  }
}
