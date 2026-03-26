import QtQuick 2.2
import Sailfish.Silica 1.0

Rectangle {
  id: step_base_root
  width: parent.width
  height: contentColumn.height
  border.color: Theme.rgba(Theme.primaryColor, 0.5)
  color: Theme.rgba(Theme.primaryColor, 0.07)
  border.width: 1

  property int stepIndex: 0
  property string stepId: ""
  property string stepType: ""
  property var stepModel 
  property var conditionsArray: []
  property string gotoTarget: ""
  property string gotoAltTarget: ""
  property var availableTargets: []
  property int totalSteps: 0

  signal moveUpRequested()
  signal moveDownRequested()
  signal removeRequested()
  signal editConditionsRequested()
  signal editGotoRequested()
  signal editParamsRequested(string reqCategory, string reqId)

  default property alias content: stepContent.data

  Column {
    id: contentColumn
    width: parent.width
    spacing: 0

    Rectangle {
      id: header_rectangle
      width: parent.width
      height: Theme.fontSizeSmall + Theme.paddingMedium
      color: Theme.rgba(Theme.primaryColor, 0.2)

      Label {
        id: step_index_label
        anchors.left: parent.left
        anchors.leftMargin: Theme.paddingSmall
        anchors.verticalCenter: parent.verticalCenter
        text: (stepIndex + 1 < 10 ? "0" : "") + (stepIndex + 1)
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
        color: Theme.highlightColor
      }

      Label {
        id: step_type_label
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        text: stepType.toUpperCase()
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
        color: Theme.highlightColor
      }

      Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5
        height: parent.height
        
        IconButton {
          icon.source: "image://theme/icon-m-up"
          width: parent.height
          height: parent.height
          icon.width: parent.height
          icon.height: parent.height
          enabled: step_base_root.stepIndex > 0
          onClicked: step_base_root.moveUpRequested()
          anchors.verticalCenter: parent.verticalCenter
        }

        IconButton {
          icon.source: "image://theme/icon-m-down"
          width: parent.height
          height: parent.height
          icon.width: parent.height
          icon.height: parent.height
          enabled: step_base_root.stepIndex < step_base_root.totalSteps - 1
          onClicked: step_base_root.moveDownRequested()
          anchors.verticalCenter: parent.verticalCenter
        }
        IconButton {
          icon.source: "image://theme/icon-m-clear"
          width: parent.height
          height: parent.height
          icon.width: parent.height
          icon.height: parent.height
          onClicked: step_base_root.removeRequested()
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    BackgroundItem {
      width: parent.width
      height: Math.max(header_rectangle.height, conditionsLabel.height + Theme.paddingSmall)
      visible: true
      onClicked: step_base_root.editConditionsRequested()
      Rectangle { anchors.bottom: parent.bottom; width: parent.width; height:1 ; color: step_base_root.border.color }
      Label {
        id: if_label
        anchors.left: parent.left
        anchors.leftMargin: Theme.paddingSmall
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
        color: Theme.secondaryHighlightColor
        text: "IF"
      }
      Label {
        id: conditionsLabel
        anchors.top: if_label.top
        anchors.left: if_label.right
        anchors.leftMargin: Theme.paddingSmall
        anchors.right: parent.right
        anchors.rightMargin: Theme.paddingSmall
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
        wrapMode: Text.Wrap
        text: {
          if (!step_base_root.conditionsArray || step_base_root.conditionsArray.length === 0) {
            return "[no conditions]"
          }

          var formatValue = function(c, side) {
            var valConst = c[side + "_const"]
            var valVar = c[side + "_var"]
            var valState = c[side + "_state"]

            if (valConst !== undefined && valConst !== "") {
              return isNaN(valConst) ? "'" + valConst + "'" : valConst
            }
            if (valVar !== undefined && valVar !== "") {
              return valVar
            }
            if (valState !== undefined && valState !== "") {
              return "state('" + valState + "')"
            }

            if (valConst === undefined) {
              return 'null'
            }

            return "''"
          }

          var final_string = ""
          for (var i = 0; i < step_base_root.conditionsArray.length; i++) {
            var c = step_base_root.conditionsArray[i]
            var left = formatValue(c, "left")
            var right = formatValue(c, "right")

            var condition_text = "[" + left + " " + c.op + " " + right + "]"

            if (i === 0) {
              final_string = condition_text
            } else {
              var logicOp = (c.logic === "or") ? " OR " : " AND "
              final_string += logicOp + condition_text
            }
          }
          return final_string
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

    Item {
      id: stepContent
      width: parent.width
      height: childrenRect.height
    }

    BackgroundItem {
      width: parent.width
      height: header_rectangle.height
      visible: true
      onClicked: step_base_root.editGotoRequested()
      Rectangle { anchors.top: parent.top; width: parent.width; height:1 ; color: step_base_root.border.color }
      Label {
        id: arrow_label
        anchors {
          left: parent.left
          leftMargin: Theme.paddingSmall
          verticalCenter: parent.verticalCenter
        }
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
        color: Theme.secondaryHighlightColor
        text: "➔"
      }

      Label {
        id: primary_target_label
        anchors {
          left: arrow_label.right
          leftMargin: Theme.paddingSmall
          right: step_base_root.gotoAltTarget !== "" ? parent.horizontalCenter : parent.right
          rightMargin: Theme.paddingSmall
          verticalCenter: parent.verticalCenter
        }
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
        truncationMode: TruncationMode.Fade
        text: {
          if (!step_base_root.gotoTarget || step_base_root.gotoTarget === "") return "Next Step"
          if (!step_base_root.availableTargets) return "Loading..." 
          for (var i = 0; i < step_base_root.availableTargets.length; i++) {
            if (step_base_root.availableTargets[i].id === step_base_root.gotoTarget) {
              return step_base_root.availableTargets[i].label
            }
          }
          return root.getStepLabel(step_base_root.gotoTarget) || "Missing/Deleted Step"
        }
      }

      Label {
        id: alt_arrow_label
        anchors {
          left: parent.horizontalCenter
          leftMargin: Theme.paddingSmall
          verticalCenter: parent.verticalCenter
        }
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
        color: Theme.secondaryHighlightColor
        text: "✕"
        visible: step_base_root.gotoAltTarget !== ""
      }

      Label {
        id: alt_target_label
        anchors {
          left: alt_arrow_label.right
          leftMargin: Theme.paddingSmall
          right: parent.right
          rightMargin: Theme.paddingSmall
          verticalCenter: parent.verticalCenter
        }
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
        truncationMode: TruncationMode.Fade
        visible: step_base_root.gotoAltTarget !== ""
        text: {
          if (!step_base_root.gotoAltTarget || step_base_root.gotoAltTarget === "") return ""
          if (!step_base_root.availableTargets) return "Loading..." 
          for (var i = 0; i < step_base_root.availableTargets.length; i++) {
            if (step_base_root.availableTargets[i].id === step_base_root.gotoAltTarget) {
              return step_base_root.availableTargets[i].label
            }
          }
          return root.getStepLabel(step_base_root.gotoAltTarget) || "Missing/Deleted Step"
        }
      }
      Icon {
        id: forward_goto_icon
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
