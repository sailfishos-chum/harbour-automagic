import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
  id: root

  property var draftConditions: []

  ListModel {
    id: conditionsModel
  }

  Component.onCompleted: {
    if (draftConditions) {
      for (var i = 0; i < draftConditions.length; i++) {
        var c = draftConditions[i]
        
        var lType = c.left_var ? "var" : (c.left_state ? "state" : "const")
        var lVal = c.left_var || c.left_state || (c.left_const !== undefined ? String(c.left_const) : "null")
        
        var rType = c.right_var ? "var" : (c.right_state ? "state" : "const")
        var rVal = c.right_var || c.right_state || (c.right_const !== undefined ? String(c.right_const) : "null")

        conditionsModel.append({
          "logic": c.logic || "and",
          "op": c.op || "==",
          "leftType": lType,
          "leftValue": lVal,
          "rightType": rType,
          "rightValue": rVal
        })
      }
    }
  }

  SilicaFlickable {
    anchors.fill: parent
    contentHeight: column.height

    Column {
      id: column
      width: parent.width
      spacing: Theme.paddingMedium

      DialogHeader {
        title: "Edit Conditions"
        acceptText: "Save"
      }

      Repeater {
        model: conditionsModel
        
        delegate: Column {
          width: parent.width
          spacing: 0

          Item {
            width: parent.width
            height: Theme.itemSizeMedium
            
            Label {
              anchors {
                left: parent.left
                leftMargin: Theme.paddingMedium
                verticalCenter: parent.verticalCenter
              }
              text: "Condition " + (index + 1)
              color: Theme.highlightColor
              font.pixelSize: Theme.fontSizeSmall
            }

            IconButton {
              icon.source: "image://theme/icon-m-clear"
              anchors {
                right: parent.right
                rightMargin: Theme.paddingSmall
                verticalCenter: parent.verticalCenter
              }
              onClicked: conditionsModel.remove(index)
            }
          }

          ComboBox {
            width: parent.width
            label: "Logic"
            leftMargin: Theme.paddingMedium
            rightMargin: Theme.paddingMedium
            visible: index > 0 
            value: model.logic === "and" ? "AND" : "OR"
            menu: ContextMenu {
              MenuItem { text: "AND"; onClicked: conditionsModel.setProperty(index, "logic", "and") }
              MenuItem { text: "OR"; onClicked: conditionsModel.setProperty(index, "logic", "or") }
            }
          }

          ComboBox {
            width: parent.width
            label: "Left Side Type"
            leftMargin: Theme.paddingMedium
            rightMargin: Theme.paddingMedium
            value: {
              if (model.leftType === "var") return "Variable"
              if (model.leftType === "state") return "State Lookup"
              return "Constant Value"
            }
            menu: ContextMenu {
              MenuItem { text: "Variable"; onClicked: conditionsModel.setProperty(index, "leftType", "var") }
              MenuItem { text: "State Lookup"; onClicked: conditionsModel.setProperty(index, "leftType", "state") }
              MenuItem { text: "Constant Value"; onClicked: conditionsModel.setProperty(index, "leftType", "const") }
            }
          }

          TextField {
            width: parent.width
            textLeftMargin: Theme.paddingMedium
            textRightMargin: Theme.paddingMedium
            label: "Left Value"
            placeholderText: model.leftType === "const" ? "e.g. 20.5 or true" : "e.g. sensor_temp"
            text: model.leftValue
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
            onTextChanged: conditionsModel.setProperty(index, "leftValue", text)
          }

          ComboBox {
            width: parent.width
            label: "Operator"
            leftMargin: Theme.paddingMedium
            rightMargin: Theme.paddingMedium
            value: model.op
            menu: ContextMenu {
              MenuItem { text: "=="; onClicked: conditionsModel.setProperty(index, "op", "==") }
              MenuItem { text: "!="; onClicked: conditionsModel.setProperty(index, "op", "!=") }
              MenuItem { text: ">"; onClicked: conditionsModel.setProperty(index, "op", ">") }
              MenuItem { text: "<"; onClicked: conditionsModel.setProperty(index, "op", "<") }
              MenuItem { text: ">="; onClicked: conditionsModel.setProperty(index, "op", ">=") }
              MenuItem { text: "<="; onClicked: conditionsModel.setProperty(index, "op", "<=") }
            }
          }

          ComboBox {
            width: parent.width
            label: "Right Side Type"
            leftMargin: Theme.paddingMedium
            rightMargin: Theme.paddingMedium
            value: {
              if (model.rightType === "var") return "Variable"
              if (model.rightType === "state") return "State Lookup"
              return "Constant Value"
            }
            menu: ContextMenu {
              MenuItem { text: "Variable"; onClicked: conditionsModel.setProperty(index, "rightType", "var") }
              MenuItem { text: "State Lookup"; onClicked: conditionsModel.setProperty(index, "rightType", "state") }
              MenuItem { text: "Constant Value"; onClicked: conditionsModel.setProperty(index, "rightType", "const") }
            }
          }

          TextField {
            width: parent.width
            textLeftMargin: Theme.paddingMedium
            textRightMargin: Theme.paddingMedium
            label: "Right Value"
            placeholderText: model.rightType === "const" ? "e.g. 20.5 or true" : "e.g. sensor_temp"
            text: model.rightValue
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
            onTextChanged: conditionsModel.setProperty(index, "rightValue", text)
          }

          Separator {
            width: parent.width
            color: Theme.primaryColor
            opacity: 0.2
            visible: index < conditionsModel.count - 1
          }
        }
      }

      Button {
        text: "Add Condition"
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: {
          conditionsModel.append({
            "logic": "and",
            "op": "==",
            "leftType": "state",
            "leftValue": "",
            "rightType": "const",
            "rightValue": ""
          })
        }
      }

      Item {
        width: parent.width
        height: Theme.paddingLarge
      }
    }
  }

  onAccepted: {
    function parseConst(val) {
      if (val === "true") return true
      if (val === "false") return false
      if (val === "null") return null
      var num = Number(val)
      if (!isNaN(num) && val.trim() !== "") return num
      return val
    }

    var final_array = []
    for (var i = 0; i < conditionsModel.count; i++) {
      var item = conditionsModel.get(i)
      
      var cond = {
        "op": item.op
      }
      
      if (i > 0) {
        cond.logic = item.logic
      }

      if (item.leftType === "var") cond.left_var = item.leftValue
      else if (item.leftType === "state") cond.left_state = item.leftValue
      else cond.left_const = parseConst(item.leftValue)

      if (item.rightType === "var") cond.right_var = item.rightValue
      else if (item.rightType === "state") cond.right_state = item.rightValue
      else cond.right_const = parseConst(item.rightValue)

      final_array.push(cond)
    }
    
    root.draftConditions = final_array
  }
}
