import QtQuick 2.2
import Sailfish.Silica 1.0

StepBase {
  id: stepBaseBranch
  stepType: "branch"
  
  property var paramsArray: []

  BackgroundItem {
    width: parent.width

    Rectangle {
      id: decision_diamond
      anchors.centerIn: parent
      width: Theme.iconSizeMedium * 0.8
      height: width
      rotation: 45
      color: "transparent"
      border.width: 2
      border.color: Theme.secondaryColor
      opacity: 0.6
    }

    Label {
      text: "IF"
      font.pixelSize: Theme.fontSizeExtraSmall
      color: Theme.secondaryColor
      anchors.centerIn: parent
    }
  }
}
