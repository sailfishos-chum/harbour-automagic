import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
  id: root

  property string mapId: ""
  property var mapData: ({})

  ListModel { id: pairsModel }

  canAccept: idField.text.trim().length > 0

  Component.onCompleted: {
    for (var k in mapData) {
      pairsModel.append({ "pKey": k, "pValue": String(mapData[k]) })
    }
  }

  SilicaFlickable {
    anchors.fill: parent
    contentHeight: column.height

    Column {
      id: column
      width: parent.width
      spacing: Theme.paddingSmall

      DialogHeader { title: root.mapId ? "Edit Map" : "New Map" }

      TextField {
        id: idField
        width: parent.width
        label: "Map ID"
        placeholderText: "e.g. switch_states"
        text: root.mapId
        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
        onTextChanged: root.mapId = text
      }

      SectionHeader { text: "Mappings" }

      Repeater {
        model: pairsModel
        delegate: Column {
          width: parent.width
          spacing: 0

          Row {
            width: parent.width
            TextField {
              width: parent.width - delBtn.width
              label: "Key (Input)"
              text: model.pKey
              inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
              onTextChanged: if (focus) pairsModel.setProperty(index, "pKey", text)
            }
            IconButton {
              id: delBtn
              icon.source: "image://theme/icon-m-clear"
              anchors.verticalCenter: parent.verticalCenter
              onClicked: pairsModel.remove(index)
            }
          }

          TextField {
            width: parent.width
            label: "Value (Output)"
            text: model.pValue
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
            onTextChanged: if (focus) pairsModel.setProperty(index, "pValue", text)
          }

          Separator { 
            width: parent.width
            color: Theme.primaryColor
            opacity: 0.8
            horizontalAlignment: Qt.AlignHCenter 
          }
        }
      }

      Button {
        text: "Add Mapping"
        anchors.horizontalCenter: parent.horizontalCenter
        preferredWidth: Theme.buttonWidthSmall
        onClicked: pairsModel.append({ "pKey": "", "pValue": "" })
      }
      
      Item { width: 1; height: Theme.paddingLarge }
    }
  }

  onAccepted: {
    var out = {}
    for (var i = 0; i < pairsModel.count; i++) {
      var item = pairsModel.get(i)
      if (item.pKey.trim() !== "") {
        var val = item.pValue
        if (val === "true") val = true
        else if (val === "false") val = false
        else if (!isNaN(val) && val.trim() !== "") val = parseFloat(val)
        
        out[item.pKey] = val
      }
    }
    root.mapData = out
  }
}
