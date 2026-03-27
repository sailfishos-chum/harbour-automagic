import QtQuick 2.2
import Sailfish.Silica 1.0

Item {
  id: actions_page

  SilicaListView {
    id: list_view
    anchors.fill: parent

    PullDownMenu {
      MenuItem {
        text: "Add Action"
        onClicked: {
          var dialog = pageStack.push(Qt.resolvedUrl("ActionEditDialog.qml"), {
            "actionData": { "enabled": true, "type": "log" }
          })
          
          dialog.accepted.connect(function() {
            var tmp = app.actions
            tmp.push(dialog.actionData)
            
            app.actions = []
            app.actions = tmp
            
            python.save_actions()
            load_items()
          })
        }
      }
    }

    header: PageHeader { title: "Actions" }

    model: ListModel { id: list_model }

    delegate: ListItem {
      id: delegate_root
      width: parent.width
      contentHeight: Theme.itemSizeMedium

      Loader {
        id: loader
        anchors.fill: parent
        source: "ActionItem.qml"
        onLoaded: {
          loader.item.itemData = model.itemData
          loader.item.index = index
        }
      }

      menu: ContextMenu {
        MenuItem {
          text: "Edit"
          onClicked: {
            var copy = JSON.parse(JSON.stringify(model.itemData))
            var dialog = pageStack.push(Qt.resolvedUrl("ActionEditDialog.qml"), {
              "actionData": copy
            })
            
            dialog.accepted.connect(function() {
              var tmp = app.actions
              var found = false
              for (var i = 0; i < tmp.length; i++) {
                if (tmp[i].id === dialog.actionData.id) {
                  tmp[i] = dialog.actionData
                  found = true
                  break
                }
              }
              
              if (found) {
                app.actions = []
                app.actions = tmp
                
                python.save_actions()
                load_items()
              }
            })
          }
        }
        MenuItem {
          text: "Copy"
          onClicked: {
            var copiedData = JSON.parse(JSON.stringify(model.itemData))
            copiedData.id = ""
            copiedData.name = ""

            var dialog = pageStack.push(Qt.resolvedUrl("ActionEditDialog.qml"), {
              "actionData": copiedData
            })

            dialog.accepted.connect(function() {
              var tmp = app.actions
              
              tmp.push(dialog.actionData)
              
              app.actions = []
              app.actions = tmp
              
              python.save_actions()
              load_items()
            })
          }
        }
        MenuItem {
          text: "Delete"
          onClicked: {
            var name = model.itemData.name || "Action"
            remorse.execute(delegate_root, "Deleting " + name, function() {
              var tmp = app.actions
              console.debug('deleting model - id:', model.id)
              for (var i = 0; i < tmp.length; i++) {
                console.debug('checkinng for deletion model - id:', tmp[i].id)
                if (tmp[i].id === model.id) {
                  tmp.splice(i, 1)
                  break
                }
              }
              app.actions = tmp
              python.save_actions()
              load_items()
            })
          }
        }
      }
    }

    ViewPlaceholder {
      enabled: list_view.count < 1
      text: "No actions"
      hintText: "Actions are the 'Do' part of flows"
    }

    VerticalScrollDecorator {}
  }

  RemorseItem { id: remorse }
  
  Component.onCompleted: {
    app.signal_update_actions.connect(handle_update_actions)
    python.load_data()
  }

  Component.onDestruction: {
    app.signal_update_actions.disconnect(handle_update_actions)
  }

  function load_items() {
    list_model.clear()
    if (!app || !app.actions) return
    for (var i = 0; i < app.actions.length; i++) {
      var act = app.actions[i]
      list_model.append({
        "id": act.id,
        "itemData": act
      })
    }
  }

  function handle_update_actions() {
    load_items()
  }
}
