import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
  id: stringPickerPage

  signal selected(string type, string id)

  property string selectedId: ""

  SilicaListView {
    anchors.fill: parent
    header: PageHeader { title: "Select Action" }
    
    model: ListModel { id: combinedModel }

    Component.onCompleted: {
      combinedModel.append({ 
        "name": "uppercase()", 
        "id": "uppercase", 
        "type": "function" 
      })
      combinedModel.append({ 
        "name": "lowercase()", 
        "id": "lowercase", 
        "type": "function" 
      })
      combinedModel.append({ 
        "name": "trim()", 
        "id": "trim", 
        "type": "function" 
      })
      combinedModel.append({ 
        "name": "replace()", 
        "id": "replace", 
        "type": "function" 
      })
      combinedModel.append({ 
        "name": "regex_replace()", 
        "id": "regex_replace", 
        "type": "function" 
      })
    }

    delegate: ListItem {
      width: parent.width

      onClicked: {
        stringPickerPage.selected(model.type, model.id)
        pageStack.pop()
      }

      Label {
        anchors.left: parent.left
        anchors.leftMargin: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter
        text: model.name
        color: (highlighted || model.id === stringPickerPage.selectedId) ? Theme.highlightColor : Theme.primaryColor
      }
    }
  }
}
