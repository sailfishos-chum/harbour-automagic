import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
  id: root

  canAccept: exportPathField.text.trim().length > 0

  ListModel { id: flowsModel }
  ListModel { id: sourcesModel }
  ListModel { id: actionsModel }
  ListModel { id: valueMapsModel }

  function _populateModels() {
    flowsModel.clear()
    for (var i = 0; i < app.flows.length; i++) {
      var f = app.flows[i]
      flowsModel.append({ "itemId": f.id, "itemName": f.name || f.id, "isChecked": false })
    }
    sourcesModel.clear()
    for (var j = 0; j < app.data_sources.length; j++) {
      var s = app.data_sources[j]
      sourcesModel.append({ "itemId": s.id, "itemName": s.name || s.id, "isChecked": false })
    }
    actionsModel.clear()
    for (var k = 0; k < app.actions.length; k++) {
      var a = app.actions[k]
      actionsModel.append({ "itemId": a.id, "itemName": a.name || a.id, "isChecked": false })
    }
    valueMapsModel.clear()
    for (var key in app.value_maps) {
      valueMapsModel.append({ "itemId": key, "itemName": key, "isChecked": false })
    }
  }

  function _selectAll(selected) {
    for (var i = 0; i < flowsModel.count; i++) flowsModel.setProperty(i, "isChecked", selected)
    for (var j = 0; j < sourcesModel.count; j++) sourcesModel.setProperty(j, "isChecked", selected)
    for (var k = 0; k < actionsModel.count; k++) actionsModel.setProperty(k, "isChecked", selected)
    for (var l = 0; l < valueMapsModel.count; l++) valueMapsModel.setProperty(l, "isChecked", selected)
  }

  function syncFlowDependencies(flowId, checked) {
    var flow = null
    for (var i = 0; i < app.flows.length; i++) {
      if (app.flows[i].id === flowId) { flow = app.flows[i]; break }
    }

    if (!flow) return

    var sourceIds = {}
    var actionIds = {}
    var triggers = flow.triggers || []
    for (var t = 0; t < triggers.length; t++) sourceIds[triggers[t]] = true
    var steps = flow.steps || []

    for (var s = 0; s < steps.length; s++) {
      if (steps[s].type === "get" && steps[s].source) sourceIds[steps[s].source] = true
      if (steps[s].type === "action" && steps[s].action) actionIds[steps[s].action] = true
    }

    for (var si = 0; si < sourcesModel.count; si++) {
      if (sourceIds[sourcesModel.get(si).itemId]) {
        sourcesModel.setProperty(si, "isChecked", checked)
        syncSourceValueMaps(sourcesModel.get(si).itemId, checked)
      }
    }
    for (var ai = 0; ai < actionsModel.count; ai++) {
      if (actionIds[actionsModel.get(ai).itemId]) {
        actionsModel.setProperty(ai, "isChecked", checked)
      }
    }
  }

  function syncSourceValueMaps(sourceId, checked) {
    for (var i = 0; i < app.data_sources.length; i++) {
      if (app.data_sources[i].id !== sourceId) continue
      var transforms = app.data_sources[i].transformations || []
      for (var t = 0; t < transforms.length; t++) {
        if (transforms[t].type !== "value_map" || !transforms[t].map) continue
        var mapName = transforms[t].map
        for (var v = 0; v < valueMapsModel.count; v++) {
          if (valueMapsModel.get(v).itemId === mapName) {
            valueMapsModel.setProperty(v, "isChecked", checked)
            break
          }
        }
      }
      break
    }
  }

  SilicaFlickable {
    anchors.fill: parent
    contentHeight: mainColumn.height

    Column {
      id: mainColumn
      width: parent.width

      DialogHeader {
        title: "Export"
        acceptText: "Export"
      }

      TextField {
        id: exportPathField
        width: parent.width
        label: "Export Folder Name"
        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
      }

      TextSwitch {
        width: parent.width
        text: "Select All"

        onCheckedChanged: {
          _selectAll(checked)
        }
      }

      ExpandingSection {
        title: "Flows"
        expanded: flowsModel.count < 10
        content.sourceComponent: Component {
          Column {
            width: parent.width
            Repeater {
              model: flowsModel
              delegate: TextSwitch {
                property bool modelChecked: model.isChecked
                width: parent.width
                text: model.itemName
                checked: modelChecked
                onModelCheckedChanged: checked = modelChecked
                onCheckedChanged: {
                  if (modelChecked === checked) return
                  flowsModel.setProperty(index, "isChecked", checked)
                  syncFlowDependencies(model.itemId, checked)
                }
              }
            }
          }
        }
      }

      ExpandingSection {
        title: "Sources"
        expanded: sourcesModel.count < 10
        content.sourceComponent: Component {
          Column {
            width: parent.width
            Repeater {
              model: sourcesModel
              delegate: TextSwitch {
                property bool modelChecked: model.isChecked
                width: parent.width
                text: model.itemName
                checked: modelChecked
                onModelCheckedChanged: checked = modelChecked
                onCheckedChanged: {
                  if (modelChecked === checked) return
                  sourcesModel.setProperty(index, "isChecked", checked)
                  syncSourceValueMaps(model.itemId, checked)
                }
              }
            }
          }
        }
      }

      ExpandingSection {
        title: "Actions"
        expanded: actionsModel.count < 10
        content.sourceComponent: Component {
          Column {
            width: parent.width
            Repeater {
              model: actionsModel
              delegate: TextSwitch {
                property bool modelChecked: model.isChecked
                width: parent.width
                text: model.itemName
                checked: modelChecked
                onModelCheckedChanged: checked = modelChecked
                onCheckedChanged: {
                  if (modelChecked === checked) return
                  actionsModel.setProperty(index, "isChecked", checked)
                }
              }
            }
          }
        }
      }

      ExpandingSection {
        title: "Value Maps"
        expanded: valueMapsModel.count < 10
        content.sourceComponent: Component {
          Column {
            width: parent.width
            Repeater {
              model: valueMapsModel
              delegate: TextSwitch {
                property bool modelChecked: model.isChecked
                width: parent.width
                text: model.itemName
                checked: modelChecked
                onModelCheckedChanged: checked = modelChecked
                onCheckedChanged: {
                  if (modelChecked === checked) return
                  valueMapsModel.setProperty(index, "isChecked", checked)
                }
              }
            }
          }
        }
      }

      Item { width: 1; height: Theme.paddingLarge }
    }
  }

  Component.onCompleted: {
    _populateModels()
    var now = new Date()
    var stamp = Qt.formatDate(now, "yyyyMMdd") + "_" + Qt.formatTime(now, "HHmmss")
    exportPathField.text = "automagic-export-" + stamp
  }

  onAccepted: {
    var base = (app.settings && app.settings.export_base_path) ? app.settings.export_base_path : ""
    var folder = base + "/" + exportPathField.text.trim() + "/"

    var selFlowIds = {}, selSrcIds = {}, selActIds = {}, selVmKeys = {}
    var i
    for (i = 0; i < flowsModel.count; i++) if (flowsModel.get(i).isChecked) selFlowIds[flowsModel.get(i).itemId] = true
    for (i = 0; i < sourcesModel.count; i++) if (sourcesModel.get(i).isChecked) selSrcIds[sourcesModel.get(i).itemId] = true
    for (i = 0; i < actionsModel.count; i++) if (actionsModel.get(i).isChecked) selActIds[actionsModel.get(i).itemId] = true
    for (i = 0; i < valueMapsModel.count; i++) if (valueMapsModel.get(i).isChecked) selVmKeys[valueMapsModel.get(i).itemId] = true

    var selectedFlows = app.flows.filter(function(f) { return selFlowIds[f.id] })
    var selectedSources = app.data_sources.filter(function(s) { return selSrcIds[s.id] })
    var selectedActions = app.actions.filter(function(a) { return selActIds[a.id] })

    var selectedMaps = {}, hasVm = false
    for (var key in selVmKeys) {
      if (app.value_maps[key] !== undefined) {
        selectedMaps[key] = app.value_maps[key]
        hasVm = true
      }
    }

    if (selectedFlows.length > 0) python.save_json_file(selectedFlows, folder + "flows.json")
    if (selectedSources.length > 0) python.save_json_file(selectedSources, folder + "data_sources.json")
    if (selectedActions.length > 0) python.save_json_file(selectedActions, folder + "actions.json")
    if (hasVm) python.save_json_file(selectedMaps, folder + "value_maps.json")
  }
}
