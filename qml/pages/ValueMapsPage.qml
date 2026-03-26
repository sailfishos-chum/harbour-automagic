import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
  id: mapsPage

  property var mapKeys: []

  function refreshKeys() {
    var keys = []
    for (var k in app.value_maps) {
      keys.push(k)
    }
    mapKeys = keys.sort()
  }

  Component.onCompleted: refreshKeys()

  SilicaListView {
    anchors.fill: parent
    header: PageHeader { title: "Value Maps" }
    model: mapsPage.mapKeys

    delegate: ListItem {
      id: delegate
      contentHeight: Theme.itemSizeMedium
      
      Label {
        text: modelData
        anchors.verticalCenter: parent.verticalCenter
        x: Theme.horizontalPageMargin
        color: Theme.primaryColor
      }

      onClicked: openEdit(modelData)

      menu: ContextMenu {
        MenuItem {
          text: "Edit"
          onClicked: openEdit(modelData)
        }
        MenuItem {
          text: "Delete"
          onClicked: {
            var targetKey = modelData
            delegate.remorseAction("Deleting " + targetKey, function() {
              var tmp = app.value_maps
              delete tmp[targetKey]
              app.value_maps = tmp
              python.save_value_maps(app.value_maps)
              refreshKeys()
            })
          }
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

      Separator {
        anchors.top: parent.top
        width: parent.width
        color: Theme.primaryColor
        opacity: 0.8
        visible: index === 0 
      }

      Separator {
        anchors.bottom: parent.bottom
        width: parent.width
        color: Theme.primaryColor
        opacity: 0.8
      }
    }

    PullDownMenu {
      MenuItem {
        text: "Add Map"
        onClicked: openEdit("")
      }
    }
  }

  function openEdit(targetId) {
    var dialog = pageStack.push(Qt.resolvedUrl("ValueMapEditDialog.qml"), {
      "mapId": targetId,
      "mapData": targetId ? JSON.parse(JSON.stringify(app.value_maps[targetId])) : {}
    })
    
    dialog.accepted.connect(function() {
      var tmp = app.value_maps
      if (targetId && targetId !== dialog.mapId) {
        delete tmp[targetId]
      }
      tmp[dialog.mapId] = dialog.mapData
      app.value_maps = tmp
      python.save_value_maps(app.value_maps)
      refreshKeys()
    })
  }
}
