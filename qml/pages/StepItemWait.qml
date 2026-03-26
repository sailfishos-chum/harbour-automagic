import QtQuick 2.2
import Sailfish.Silica 1.0

StepBase {
  id: stepBaseWait
  stepType: "wait"
  
  property var paramsArray: []

  Column {
    width: parent.width
    spacing: 0

    BackgroundItem {
      width: parent.width
      height: delay_container.height + (Theme.paddingSmall * 2)
      onClicked: stepBaseWait.editParamsRequested("step_types", "wait")

      Label {
        id: durationLabel
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.secondaryColor
        text: {
          if (!paramsArray || paramsArray.length === 0) return "1s"
          for (var i = 0; i < paramsArray.length; i++) {
            if (paramsArray[i].key === "duration") return paramsArray[i].value
          }
          return "1s"
        }
      }

      Item {
        id: delay_container
        anchors.centerIn: parent
        width: durationLabel.width + (Theme.paddingLarge * 2)
        height: Theme.iconSizeMedium * 0.7
        visible: stepType === "wait"
        clip: true

        Rectangle {
          id: delay_shape
          width: parent.width * 2
          height: parent.height
          anchors.left: parent.left
          anchors.leftMargin: -parent.width
          
          color: "transparent"
          border.width: 2
          border.color: Theme.secondaryColor
          opacity: 0.6
          radius: height / 2
        }

        Rectangle {
          anchors {
            left: parent.left
            top: delay_shape.top
            bottom: delay_shape.bottom
          }
          width: 2
          color: Theme.secondaryColor
          opacity: 0.6
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
}
