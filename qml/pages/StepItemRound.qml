import QtQuick 2.2
import Sailfish.Silica 1.0

StepBase {
  id: stepBaseRound
  stepType: "round"
  
  property var paramsArray: []

  Column {
    width: parent.width
    spacing: 0

    BackgroundItem {
      width: parent.width
      height: Theme.itemSizeMedium
      onClicked: stepBaseRound.editParamsRequested("step_types", "round")

      Rectangle {
        anchors.fill: parent
        color: Theme.highlightColor
        opacity: 0.1
      }

      Column {
        anchors.centerIn: parent
        spacing: Theme.paddingSmall

        Label {
          anchors.horizontalCenter: parent.horizontalCenter
          text: {
            var dec = "0";
            for (var i = 0; i < paramsArray.length; i++) {
              if (paramsArray[i].key === "decimals") dec = paramsArray[i].value;
            }
            return dec + " decimals"
          }
          font.pixelSize: Theme.fontSizeMedium
          font.bold: true
          color: Theme.primaryColor
        }

        Label {
          anchors.horizontalCenter: parent.horizontalCenter
          font.pixelSize: Theme.fontSizeSmall
          color: Theme.secondaryColor
          text: {
            var input = "?", output = "?";
            for (var i = 0; i < paramsArray.length; i++) {
              if (paramsArray[i].key === "in") input = paramsArray[i].value;
              if (paramsArray[i].key === "out") output = paramsArray[i].value;
            }
            return input + " → " + output
          }
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
