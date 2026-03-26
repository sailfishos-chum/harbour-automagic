import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
  id: root
  
  property var existing: [] 
  
  signal sourceSelected(string sourceId)

  SilicaListView {
    id: listView
    anchors.fill: parent

    header: PageHeader {
      title: "Select Trigger"
    }

    model: ListModel {
      id: listModel
    }

    delegate: ListItem {
      id: delegateRoot
      width: parent.width
      contentHeight: Theme.itemSizeSmall

      Label {
        text: model.name
        color: delegateRoot.highlighted ? Theme.highlightColor : Theme.primaryColor
        truncationMode: TruncationMode.Fade
        anchors {
          left: parent.left
          leftMargin: Theme.horizontalPageMargin
          right: parent.right
          rightMargin: Theme.horizontalPageMargin
          verticalCenter: parent.verticalCenter
        }
      }

      onClicked: {
        root.sourceSelected(model.id)
        pageStack.pop()
      }
    }

    Component.onCompleted: {
      loadAvailableSources()
    }

    function loadAvailableSources() {
      listModel.clear()
      if (!app || !app.data_sources) return

      for (var i = 0; i < app.data_sources.length; i++) {
        var source = app.data_sources[i]
        
        if (source.trigger === true && root.existing.indexOf(source.id) === -1) {
          listModel.append({
            "id": source.id,
            "name": source.name
          })
        }
      }
    }
  }
}
