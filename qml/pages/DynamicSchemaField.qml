import QtQuick 2.2
import Sailfish.Silica 1.0

Item {
  id: rootItem
  width: parent.width
  height: childrenRect.height

  property var fieldSchema: ({})
  property string labelText: ""
  property var currentValue 

  signal valueChanged(var newValue) 

  Loader {
    id: controlLoader
    width: parent.width
    sourceComponent: rootItem.fieldSchema.options ? comboComponent : textComponent
  }

  Component {
    id: textComponent
    TextArea {
      label: rootItem.labelText
      placeholderText: rootItem.fieldSchema.placeholder || rootItem.labelText
      text: rootItem.currentValue !== undefined ? String(rootItem.currentValue) : ""
      wrapMode: TextEdit.Wrap
      inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly

      Keys.onReturnPressed: {
        event.accepted = true
        focus = false
      }
      Keys.onEnterPressed: {
        event.accepted = true
        focus = false
      }

      onTextChanged: {
        if (focus) {
          rootItem.valueChanged(text)
        }
      }
    }
  }

  Component {
    id: comboComponent
    ComboBox {
      id: silicaCombo
      label: rootItem.labelText
      
      readonly property var optionArray: rootItem.fieldSchema.options || []

      function syncIndex() {
        for (var i = 0; i < optionArray.length; i++) {
          if (String(optionArray[i].value) === String(rootItem.currentValue)) {
            silicaCombo.currentIndex = i
            return
          }
        }
        silicaCombo.currentIndex = 0
      }

      Component.onCompleted: {
        syncIndex()
      }

      Connections {
        target: rootItem
        onCurrentValueChanged: {
          silicaCombo.syncIndex()
        }
      }

      menu: ContextMenu {
        Repeater {
          model: silicaCombo.optionArray
          MenuItem {
            text: modelData.label
            onClicked: {
              rootItem.valueChanged(modelData.value)
            }
          }
        }
      }
    }
  }
}
