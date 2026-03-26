import QtQuick 2.2
import Sailfish.Silica 1.0

StepBase {
  id: stepBaseMath
  stepType: "math"
  
  property var paramsArray: []

  BackgroundItem {
    width: parent.width
    height: Theme.itemSizeMedium
    onClicked: stepBaseMath.editParamsRequested("step_types", "math")

    Rectangle {
      anchors.fill: parent
      color: Theme.highlightColor
      opacity: 0.1
    }

    Column {
      anchors.centerIn: parent
      spacing: Theme.paddingSmall
      width: parent.width - Theme.paddingLarge * 2

      Label {
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: {
          var expr = "0";
          for (var i = 0; i < paramsArray.length; i++) {
            if (paramsArray[i].key === "in") expr = paramsArray[i].value;
          }
          return expr === "" ? "[no expression]" : expr
        }
        font.pixelSize: Theme.fontSizeMedium
        font.bold: true
        color: Theme.primaryColor
      }

      Label {
        anchors.horizontalCenter: parent.horizontalCenter
        text: {
          var output = "?";
          for (var i = 0; i < paramsArray.length; i++) {
            if (paramsArray[i].key === "out") output = paramsArray[i].value;
          }
          return "→ " + output
        }
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.secondaryColor
      }
    }

    Icon {
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
