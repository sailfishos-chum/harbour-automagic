import QtQuick 2.2
import Sailfish.Silica 1.0

Item {
  id: data_sources_page

  SilicaListView {
    id: list_view
    anchors.fill: parent

    PullDownMenu {
      MenuItem {
        text: "Value Maps"
        onClicked: {
          pageStack.push(Qt.resolvedUrl("ValueMapsPage.qml"), {})
        }
      }
      MenuItem {
        text: "Add Source"
        onClicked: {
          var dialog = pageStack.push(Qt.resolvedUrl("SourceEditDialog.qml"), {
            "sourceData": { "name": "", "type": "file", "enabled": true, "trigger": false }
          })
          
          dialog.accepted.connect(function() {
            var tmp = app.data_sources
            tmp.push(dialog.sourceData)
            app.data_sources = tmp
            python.save_data_sources()
            load_items()
          })
        }
      }
    }

    header: PageHeader { title: "Sources" }

    model: ListModel { id: list_model }

    delegate: ListItem {
      id: delegate_root
      width: parent.width
      contentHeight: Theme.itemSizeMedium

      Loader {
        id: loader
        anchors.fill: parent
        source: isTrigger ? "TriggerItem.qml" : "SourceItem.qml"
        onLoaded: {
          loader.item.itemData = model.itemData
          loader.item.index = index
        }
      }

      menu: ContextMenu {
        MenuItem {
          text: "Edit"
          onClicked: {
            var dialog = pageStack.push(Qt.resolvedUrl("SourceEditDialog.qml"), {
              "sourceData": model.itemData
            })
            
            dialog.accepted.connect(function() {
              var tmp = app.data_sources
              var found = false
              
              for (var i = 0; i < tmp.length; i++) {
                if (tmp[i].id === dialog.sourceData.id) {
                  tmp[i] = dialog.sourceData
                  found = true
                  break
                }
              }
              
              if (!found) {
                tmp.push(dialog.sourceData)
              }
              
              app.data_sources = tmp
              python.save_data_sources()
              load_items()
            })
          }
        }
        MenuItem {
          text: "Copy"
          onClicked: {
            var copiedData = JSON.parse(JSON.stringify(model.itemData))
            copiedData.id = ""
            copiedData.name = ""

            var dialog = pageStack.push(Qt.resolvedUrl("SourceEditDialog.qml"), {
              "sourceData": copiedData
            })

            dialog.accepted.connect(function() {
              var tmp = app.data_sources
              tmp.push(dialog.sourceData)
              app.data_sources = tmp
              python.save_data_sources()
              load_items()
            })
          }
        }
        MenuItem {
          text: "Delete"
          onClicked: {
            var name = model.itemData.name || "Source"
            remorse.execute(delegate_root, "Deleting " + name, function() {
              var tmp = app.data_sources
              for (var i = 0; i < tmp.length; i++) {
                if (tmp[i].id === model.id) {
                  tmp.splice(i, 1)
                  break
                }
              }
              app.data_sources = tmp
              python.save_data_sources()
              load_items()
            })
          }
        }
        MenuItem {
          visible: isTrigger
          text: "Execute trigger"
          onClicked: python.exec_trigger(model.id)
        }
      }
    }

    ViewPlaceholder {
      enabled: list_view.count < 1
      text: "No data sources"
    }

    VerticalScrollDecorator {}
  }

  RemorseItem { id: remorse }

  Component.onCompleted: load_items()

  Connections {
    target: app
    function onTriggersChanged() { load_items() }
  }

  function load_items() {
    list_model.clear()
    for (var i = 0; i < app.data_sources.length; i++) {
      var ds = app.data_sources[i]
      list_model.append({
        "id": ds.id,
        "isTrigger": !!ds.trigger,
        "itemData": ds
      })
    }
  }
}
