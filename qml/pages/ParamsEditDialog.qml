import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
  id: root

  property string templateCategory: "action_types" 
  property string itemId: "" 
  property var draftParams: [] 

  property var currentTemplate: null
  property var formValues: ({})

  ListModel { id: customParamsModel }

  canAccept: true

  Component.onCompleted: {
    if (app.templates && app.templates.ui_schema && templateCategory && app.templates.ui_schema[templateCategory]) {
      currentTemplate = app.templates.ui_schema[templateCategory][itemId]
    }

    var tempVals = {}
    for (var j = 0; j < draftParams.length; j++) {
      tempVals[draftParams[j].key] = draftParams[j].value
      
      customParamsModel.append({
        "pKey": draftParams[j].key || "",
        "pValue": draftParams[j].value !== undefined ? String(draftParams[j].value) : "",
        "pType": draftParams[j].type || "string"
      })
    }
    formValues = tempVals
  }

  SilicaFlickable {
    anchors.fill: parent
    contentHeight: mainColumn.height

    Column {
      id: mainColumn
      width: parent.width
      spacing: Theme.paddingMedium

      DialogHeader {
        title: currentTemplate ? currentTemplate.name : "Parameters"
      }

      Column {
        width: parent.width
        visible: !!currentTemplate
        spacing: Theme.paddingMedium

        Label {
          visible: currentTemplate ? (currentTemplate.fields.length === 0) : false
          text: "No additional parameters needed for this item."
          color: Theme.secondaryColor
          x: Theme.horizontalPageMargin
          width: parent.width - (Theme.horizontalPageMargin * 2)
          wrapMode: Text.Wrap
        }

        Repeater {
          model: currentTemplate ? currentTemplate.fields : []
          delegate: Column {
            id: fieldDelegate
            width: parent.width
            spacing: 0

            readonly property var myFieldData: modelData
            readonly property bool isExclusive: Array.isArray(myFieldData)
            
            property int selectedIdx: {
              if (!isExclusive) return 0
              for (var i = 0; i < myFieldData.length; i++) {
                for (var j = 0; j < root.draftParams.length; j++) {
                  if (root.draftParams[j].key === myFieldData[i].key && root.draftParams[j].value !== "") {
                    return i
                  }
                }
              }
              return 0
            }

            ComboBox {
              id: combo
              width: parent.width
              visible: isExclusive
              label: "Source"
              currentIndex: selectedIdx
              
              menu: ContextMenu {
                Repeater {
                  model: isExclusive ? myFieldData : []
                  MenuItem {
                    text: modelData.label.replace("From ", "")
                    onClicked: {
                      selectedIdx = index
                      var temp = root.formValues
                      for (var j = 0; j < myFieldData.length; j++) {
                        if (j !== index) {
                          delete temp[myFieldData[j].key]
                        }
                      }
                      root.formValues = temp
                    }
                  }
                }
              }
            }

            Label {
              text: isExclusive ? "[" + myFieldData[selectedIdx].key + "]" : "[" + myFieldData.key + "]"
              font.pixelSize: Theme.fontSizeExtraSmall
              color: Theme.secondaryHighlightColor
              x: Theme.horizontalPageMargin
            }

            DynamicSchemaField {
              width: parent.width
              
              fieldSchema: isExclusive ? myFieldData[selectedIdx] : myFieldData
              
              labelText: isExclusive ? myFieldData[selectedIdx].label.replace("From ", "") : myFieldData.label
              
              currentValue: {
                var k = isExclusive ? myFieldData[selectedIdx].key : myFieldData.key
                var v = root.formValues[k]
                return v !== undefined ? String(v) : ""
              }

              onValueChanged: {
                var k = isExclusive ? myFieldData[selectedIdx].key : myFieldData.key
                var temp = root.formValues
                temp[k] = newValue
                root.formValues = temp
              }
            }
          }
        }
      }

      Column {
        width: parent.width
        visible: !currentTemplate
        spacing: Theme.paddingMedium

        Label {
          text: "Custom Parameters"
          color: Theme.highlightColor
          font.pixelSize: Theme.fontSizeLarge
          x: Theme.horizontalPageMargin
        }

        Repeater {
          model: customParamsModel
          
          delegate: Column {
            width: parent.width
            spacing: 0

            Row {
              width: parent.width
              spacing: Theme.paddingSmall

              TextField {
                width: parent.width - icon_button.width - Theme.paddingMedium
                label: "Parameter Key"
                placeholderText: "key"
                text: model.pKey
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
                onTextChanged: {
                  if (focus) {
                    customParamsModel.setProperty(index, "pKey", text)
                  }
                }
              }

              IconButton {
                id: icon_button
                icon.source: "image://theme/icon-m-clear"
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                  customParamsModel.remove(index)
                }
              }
            }

            TextArea {
              width: parent.width - Theme.paddingMedium
              label: "Value"
              placeholderText: "Enter value or {{variable}}"
              text: model.pValue
              inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
              onTextChanged: {
                if (focus) {
                  customParamsModel.setProperty(index, "pValue", text)
                }
              }
            }

            Separator {
              width: parent.width
              color: Theme.secondaryHighlightColor
              horizontalAlignment: Qt.AlignHCenter
            }
            
            Item { width: 1; height: Theme.paddingMedium }
          }
        }

        Button {
          text: "Add Parameter"
          anchors.horizontalCenter: parent.horizontalCenter
          onClicked: {
            customParamsModel.append({"pKey": "", "pValue": "", "pType": "string"})
          }
        }
      }
      
      Item { width: 1; height: Theme.paddingLarge }
    }
  }

  onAccepted: {
    var packed = []

    if (currentTemplate) {
      for (var i = 0; i < currentTemplate.fields.length; i++) {
        var field = currentTemplate.fields[i]
        if (Array.isArray(field)) {
          for (var j = 0; j < field.length; j++) {
            if (root.formValues[field[j].key] !== undefined) {
              packed.push({
                "key": field[j].key,
                "type": "string",
                "value": String(root.formValues[field[j].key])
              })
              break 
            }
          }
        } else {
          var v = root.formValues[field.key] !== undefined ? root.formValues[field.key] : (field.default || "")

          if (field.ui_type === "array") {
            var fields = []
            var f = String(v).split(",")
            for (var k = 0; k < f.length; k++) {
              fields.push(f[k].trim())
            }
            packed.push({
              "key": field.key,
              "type": "array",
              "value": fields
            })
          } else {
            packed.push({
              "key": field.key,
              "type": field.ui_type === "number" ? "number" : (field.ui_type === "boolean" ? "bool" : "string"),
              "value": String(v)
            })
          }
        }
      }
    } else {
      for (var m = 0; m < customParamsModel.count; m++) {
        var p = customParamsModel.get(m)
        if (p.pKey && String(p.pKey).trim() !== "") {
          packed.push({
            "key": String(p.pKey).trim(),
            "type": p.pType || "string",
            "value": String(p.pValue)
          })
        }
      }
    }

    root.draftParams = packed
  }
}
