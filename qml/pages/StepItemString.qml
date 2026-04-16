import QtQuick 2.2
import Sailfish.Silica 1.0

StepBase {
  id: stepBase
  stepType: "string"
  
  property string targetType: "string"
  property string functionId: ""
  property var paramsArray: []

  signal changeStringRequested()

  Column {
    width: parent.width
    spacing: 0

    BackgroundItem {
      width: parent.width
      height: Theme.itemSizeSmall
      onClicked: stepBase.changeStringRequested()
      Label {
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
        color: Theme.primaryColor

        text: {
          if (functionId !== "") {
            return functionId + "()"
          }

          return "Select String Function..."
        }
      }

      Icon {
        id: forward_action_icon
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

    BackgroundItem {
      width: parent.width
      height: paramsLabel.height + Theme.paddingSmall
      visible: functionId !== ""
      onClicked: {
        stepBase.editParamsRequested("step_types", "string_" + functionId)
      }
      Label {
        id: paramsLabel
        width: parent.width - (Theme.paddingLarge * 2)
        anchors.horizontalCenter: parent.horizontalCenter
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
        wrapMode: Text.Wrap
        text: {
          if (!paramsArray || paramsArray.length === 0) {
            return "[no parameters]"
          }
          var lines = []
          for (var i=0; i<paramsArray.length; i++) {
            lines.push(paramsArray[i].key + ": " + paramsArray[i].value)
          }
          return lines.join("\n")
        }
      }
      Icon {
        id: forward_params_icon
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
