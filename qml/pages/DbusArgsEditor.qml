import QtQuick 2.2
import Sailfish.Silica 1.0

Column {
  id: root
  width: parent.width
  property var argsModel
  property var onChanged

  SectionHeader { text: "D-Bus Arguments" }

  Repeater {
    model: root.argsModel
    delegate: Column {
      width: parent.width
      readonly property int delegateIndex: index
      readonly property bool isCustom: {
        var standards = ["s", "u", "i", "b", "string", "uint32", "int", "int32", "bool", "boolean"]
        return standards.indexOf(model.aType) === -1
      }

      Row {
        width: parent.width
        ComboBox {
          visible: !isCustom
          width: parent.width - delArgBtn.width
          label: "Type"
          currentIndex: {
            var t = String(model.aType).toLowerCase()
            if (t === "s" || t === "string") return 0
            if (t === "u" || t === "uint32") return 1
            if (t === "i" || t === "int" || t === "int32") return 2
            if (t === "b" || t === "bool" || t === "boolean") return 3
            return 0
          }
          menu: ContextMenu {
            MenuItem { text: "s (string)"; onClicked: argsModel.setProperty(delegateIndex, "aType", "s") }
            MenuItem { text: "u (uint32)"; onClicked: argsModel.setProperty(delegateIndex, "aType", "u") }
            MenuItem { text: "i (int32)"; onClicked: argsModel.setProperty(delegateIndex, "aType", "i") }
            MenuItem { text: "b (boolean)"; onClicked: argsModel.setProperty(delegateIndex, "aType", "b") }
            MenuItem { text: "Custom..."; onClicked: argsModel.setProperty(delegateIndex, "aType", "") }
          }
        }
        TextField {
          visible: isCustom
          width: parent.width - delArgBtn.width
          label: "Signature"
          placeholderText: "e.g. as"
          text: model.aType
          inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
          onTextChanged: if (focus) argsModel.setProperty(delegateIndex, "aType", text)
        }
        IconButton {
          id: delArgBtn
          icon.source: "image://theme/icon-m-clear"
          anchors.verticalCenter: parent.verticalCenter
          onClicked: {
            argsModel.remove(delegateIndex)
            if (root.onChanged) root.onChanged()
          }
        }
      }
      TextArea {
        width: parent.width
        label: "Value"
        text: model.aValue
        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
        onTextChanged: {
          if (focus) {
            argsModel.setProperty(delegateIndex, "aValue", text)
            if (root.onChanged) root.onChanged()
          }
        }
      }
      Separator { width: parent.width; color: Theme.primaryColor; opacity: 0.3 }
    }
  }

  Button {
    text: "Add Argument"
    anchors.horizontalCenter: parent.horizontalCenter
    preferredWidth: Theme.buttonWidthSmall
    onClicked: {
      argsModel.append({ "aType": "s", "aValue": "" })
      if (root.onChanged) root.onChanged()
    }
  }
}
