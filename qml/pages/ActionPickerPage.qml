import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
  id: actionPickerPage

  signal selected(string type, string id)

  property string selectedId: ""

  SilicaListView {
    anchors.fill: parent
    header: PageHeader { title: "Select Action" }
    
    model: ListModel { id: combinedModel }

    Component.onCompleted: {
      combinedModel.append({ 
        "name": "set_state()", 
        "id": "set_state", 
        "type": "function" 
      })
      
      if (app && app.actions) {
        for (var i = 0; i < app.actions.length; i++) {
          combinedModel.append({ 
            "name": app.actions[i].name, 
            "id": app.actions[i].id, 
            "type": "action" 
          })
        }
      }
    }

    delegate: ListItem {
      width: parent.width

      onClicked: {
        actionPickerPage.selected(model.type, model.id)
        pageStack.pop()
      }

      Label {
        anchors.left: parent.left
        anchors.leftMargin: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter
        text: model.name
        color: (highlighted || model.id === actionPickerPage.selectedId) ? Theme.highlightColor : Theme.primaryColor
      }
    }
  }
}
