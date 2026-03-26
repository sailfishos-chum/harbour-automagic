import QtQuick 2.2
import Sailfish.Silica 1.0

Item {
  id: flows_page

  SilicaListView {
    id: list_view
    anchors.fill: parent

    PullDownMenu {
      MenuItem {
        text: "Library"
        onClicked: {
          pageStack.push(Qt.resolvedUrl("LibraryPage.qml"), {})
        }
      }
      MenuItem {
        text: "Add Flow"
        onClicked: {
          var dialog = pageStack.push(Qt.resolvedUrl("FlowEditDialog.qml"), {
            "flowData": { "name": "", "enabled": true, "triggers": [], "steps": [] }
          })
          dialog.accepted.connect(function() {
            python.save_flows()
          })
        }
      }
    }

    header: PageHeader { title: "Flows" }

    model: ListModel { id: list_model }

    delegate: ListItem {
      id: delegate_root
      width: parent.width
      contentHeight: Theme.itemSizeMedium

      Loader {
        id: loader
        anchors.fill: parent
        source: "FlowItem.qml"
        onLoaded: {
          loader.item.itemData = model.itemData
          loader.item.displayTriggerName = model.displayTriggerName
          loader.item.index = index
        }
      }

      menu: ContextMenu {
        MenuItem {
          text: "Edit"
          onClicked: {
            var dialog = pageStack.push(Qt.resolvedUrl("FlowEditDialog.qml"), {
              "flowData": model.itemData
            })
            dialog.accepted.connect(function() {
              python.save_flows()
            })
          }
        }
        MenuItem {
          text: "Copy"
          onClicked: {
            var copiedData = JSON.parse(JSON.stringify(model.itemData))
            copiedData.id = ""
            copiedData.name = ""

            var dialog = pageStack.push(Qt.resolvedUrl("FlowEditDialog.qml"), {
              "flowData": copiedData
            })

            dialog.accepted.connect(function() {
              python.save_flows()
            })
          }
        }
        MenuItem {
          text: "Delete"
          onClicked: {
            var flowId = model.id
            var flowName = model.itemData.name
            remorse.execute(delegate_root, "Deleting " + flowName, function() {
              var tmp = app.flows
              for (var i = 0; i < tmp.length; i++) {
                if (tmp[i].id === flowId) {
                  tmp.splice(i, 1)
                  break
                }
              }
              app.flows = tmp
                python.save_flows()
              load_items()
            })
          }
        }
        MenuItem {
          text: "Execute Flow"
          onClicked: {
            python.exec_flow(model.itemData.id)
          }
        }
      }
    }

    ViewPlaceholder {
      enabled: list_view.count < 1
      text: "No flows"
      hintText: "Create flow to use triggers and actions"
    }

    VerticalScrollDecorator {}
  }

  RemorseItem { id: remorse }

  function handle_update_flows(data) {
    load_items()
  }

  function handle_update_sources(data) {
    load_items()
  }

  Component.onCompleted: {
    app.signal_update_flows.connect(handle_update_flows)
    app.signal_update_data_sources.connect(handle_update_sources)
    python.load_data()
  }

  Component.onDestruction: {
    app.signal_update_flows.disconnect(handle_update_flows)
    app.signal_update_data_sources.disconnect(handle_update_sources)
  }

  function load_items() {
    list_model.clear()
    if (!app || !app.flows) return

    for (var i = 0; i < app.flows.length; i++) {
      var flow = app.flows[i]
      var triggerNames = [] 

      if (flow.triggers && flow.triggers.length > 0 && app.data_sources) {
        for (var j = 0; j < flow.triggers.length; j++) {
          var triggerId = flow.triggers[j]
          for (var k = 0; k < app.data_sources.length; k++) {
            if (app.data_sources[k].id === triggerId) {
              triggerNames.push(app.data_sources[k].name || app.data_sources[k].id)
              break
            }
          }
        }
      }

      list_model.append({
        "id": flow.id,
        "itemData": flow,
        "displayTriggerName": triggerNames.join(", ")
      })
    }
  }
}
