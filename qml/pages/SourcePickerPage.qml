import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
  id: sourcePickerPage

  signal selected(string type, string id)
  
  property string selectedId: ""

  SilicaListView {
    anchors.fill: parent
    header: PageHeader { title: "Select Source" }
    
    model: ListModel { id: combinedModel }

    Component.onCompleted: {
      var internalFns = ["time", "darkness", "device", "random", "state"]
      for (var i = 0; i < internalFns.length; i++) {
        combinedModel.append({
          "name": internalFns[i] + "()",
          "id": internalFns[i],
          "type": "function"
        })
      }

      var sources = app.data_sources
      if (sources) {
        for (var j = 0; j < sources.length; j++) {
          if (sources[j].trigger) continue
          
          combinedModel.append({
            "name": sources[j].name || sources[j].id,
            "id": sources[j].id,
            "type": "source"
          })
        }
      }
    }

    delegate: ListItem {
      width: parent.width

      onClicked: {
        sourcePickerPage.selected(model.type, model.id)
        pageStack.pop()
      }

      Label {
        anchors.left: parent.left
        anchors.leftMargin: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter
        text: model.name
        color: (highlighted || model.id === sourcePickerPage.selectedId) ? Theme.highlightColor : Theme.primaryColor
      }
    }
  }
}
