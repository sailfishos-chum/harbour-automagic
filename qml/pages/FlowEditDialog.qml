import QtQuick 2.2
import Sailfish.Silica 1.0
import QtQml.Models 2.2

Dialog {
  id: root
  property var flowData
  property string editedName: flowData ? (flowData.name || "") : ""
  property var editedTriggers: flowData ? (flowData.triggers || []) : []
  property bool editedEnabled: flowData && flowData.enabled !== undefined ? flowData.enabled : true

  canAccept: editedName.trim().length > 0

  ObjectModel { id: uiStepsModel }

  function generateId(step_type) {
    return "step_" + step_type + "_" + Math.random().toString(36).substr(2, 9)
  }

  function updateTargets() {
    var targets = []
    for (var i = 0; i < uiStepsModel.count; i++) {
      var item = uiStepsModel.get(i)
      targets.push({
        "id": item.stepId,
        "label": "Step " + (i + 1) + " (" + item.stepType.toUpperCase() + ")"
      })
    }
    for (var j = 0; j < uiStepsModel.count; j++) {
      uiStepsModel.get(j).availableTargets = targets
    }
  }

  function refreshIndices() {
    for (var i = 0; i < uiStepsModel.count; i++) {
      var item = uiStepsModel.get(i)
      item.stepIndex = i
      item.totalSteps = uiStepsModel.count
    }
    updateTargets()
  }

  function getStepLabel(gotoTarget) {
    if (!gotoTarget || gotoTarget === "" || gotoTarget === "next") return "Next Step"
    if (gotoTarget === "end") return "End Flow"
    
    var stepsArray = flowData.steps || []
    
    for (var i = 0; i < stepsArray.length; i++) {
      if (stepsArray[i].id === gotoTarget) {
        var s = stepsArray[i]
        var stepType = s.type ? s.type.charAt(0).toUpperCase() + s.type.slice(1) : "Unknown"
        return "Step " + (i + 1) + " (" + stepType + ")"
      }
    }
    
    return "Missing/Deleted Step"
  }

  function createStepUI(stepTypeString, initialData) {
    var capitalized = stepTypeString.charAt(0).toUpperCase() + stepTypeString.slice(1)
    var file = "StepItem" + capitalized + ".qml"
    var component = Qt.createComponent(Qt.resolvedUrl(file))

    if (component.status !== Component.Ready) {
      component = Qt.createComponent(Qt.resolvedUrl("StepItemDefault.qml"))
    }

    if (component.status === Component.Ready) {
      var item = component.createObject(null, {
        "stepId": initialData.stepId || generateId(stepTypeString),
        "stepType": stepTypeString,
        "stepModel": uiStepsModel,
        "conditionsArray": initialData.conditionsArray || [],
        "gotoTarget": initialData.gotoTarget || "",
        "gotoAltTarget": initialData.gotoAltTarget || ""
      })

      if (!item) return

      item.editParamsRequested.connect(function(reqCategory, reqId) {
        var dialog = pageStack.push(Qt.resolvedUrl("ParamsEditDialog.qml"), {
          "templateCategory": "step_functions",
          templateCategory: reqCategory || "actions",
          itemId: reqId || "",
          draftParams: item.paramsArray || []
        })

        dialog.accepted.connect(function() {
          item.paramsArray = dialog.draftParams
        })
      })

      if (stepTypeString === "action") {
        item.targetType = initialData.targetType || "action"
        item.actionId = initialData.actionId || ""
        item.functionId = initialData.functionId || ""
        item.paramsArray = initialData.paramsArray || []
        
        item.changeActionRequested.connect(function() {
          var currentId = item.targetType === "function" ? item.functionId : item.actionId
          var picker = pageStack.push(Qt.resolvedUrl("ActionPickerPage.qml"), { "selectedId": currentId })
          picker.selected.connect(function(t, id) {
            item.targetType = t
            if (t === "function") { item.functionId = id; item.actionId = "" }
            else { item.actionId = id; item.functionId = "" }
          })
        })
      } else if (stepTypeString === "wait") {
        item.paramsArray = initialData.paramsArray || []
      } else if (stepTypeString === "throttle") {
        item.paramsArray = initialData.paramsArray || []
      } else if (stepTypeString === "string") {
        item.paramsArray = initialData.paramsArray || []
        item.functionId = initialData.functionId || ""

        console.debug("STRING - function:", initialData.functionId)

        item.changeStringRequested.connect(function() {
          var picker = pageStack.push(Qt.resolvedUrl("StringFunctionPickerPage.qml"), { "selectedId": item.functionId })
          picker.selected.connect(function(t, id) {
            item.functionId = id;
          })
        })

      } else if (stepTypeString === "round") {
        item.paramsArray = initialData.paramsArray || []
      } else if (stepTypeString === "math") {
        item.paramsArray = initialData.paramsArray || []
      } else if (stepTypeString === "get") {
        item.sourceId = initialData.sourceId || ""
        item.functionId = initialData.functionId || ""
        item.paramsArray = initialData.paramsArray || []
        
        item.changeSourceRequested.connect(function() {
          var currentId = item.functionId !== "" ? item.functionId : item.sourceId
          
          var picker = pageStack.push(Qt.resolvedUrl("SourcePickerPage.qml"), {
            "selectedId": currentId
          })
          
          picker.selected.connect(function(t, id) {
            if (t === "function") { 
              item.functionId = id; item.sourceId = "" 
            } else { 
              item.sourceId = id; item.functionId = "" 
            }
          })
        })
      }

      item.moveUpRequested.connect(function() {
        var idx = item.stepIndex
        if (idx > 0) { 
          uiStepsModel.move(idx, idx - 1, 1)
          refreshIndices() 
        }
      })
      
      item.moveDownRequested.connect(function() {
        var idx = item.stepIndex
        if (idx < uiStepsModel.count - 1) { 
          uiStepsModel.move(idx, idx + 1, 1)
          refreshIndices() 
        }
      })
      
      item.removeRequested.connect(function() {
        var idx = item.stepIndex
        var deletedId = uiStepsModel.get(idx).stepId
        uiStepsModel.remove(idx)
        item.destroy()

        for (var i = 0; i < uiStepsModel.count; i++) {
          var itm = uiStepsModel.get(i)
          if (itm.gotoTarget === deletedId) itm.gotoTarget = ""
          if (itm.gotoAltTarget === deletedId) itm.gotoAltTarget = ""
        }

        refreshIndices()
      })
      
      item.editConditionsRequested.connect(function() {
        var dialog = pageStack.push("ConditionEditDialog.qml", { "draftConditions": item.conditionsArray ? item.conditionsArray.slice() : [] })
        dialog.accepted.connect(function() { item.conditionsArray = dialog.draftConditions })
      })

      item.editGotoRequested.connect(function() {
        var targetList = []
        
        targetList.push({"id": "", "label": "Next Step" })

        var liveTargets = item.availableTargets || [] 
        
        for (var i = 0; i < liveTargets.length; i++) {
          var s = liveTargets[i]
          
          if (s.id !== item.stepId) { 
            targetList.push({
              "id": s.id,
              "label": s.label 
            })
          }
        }

        targetList.push({ "id": "end", "label": "End Flow" })

        var dialog = pageStack.push(Qt.resolvedUrl("GotoEditDialog.qml"), {
          "draftGotoTarget": item.gotoTarget || "",
          "draftGotoAltTarget": item.gotoAltTarget || "",
          "availableSteps": targetList
        })

        dialog.accepted.connect(function() { 
          item.gotoTarget = dialog.draftGotoTarget
          item.gotoAltTarget = dialog.draftGotoAltTarget
        })
      })

      uiStepsModel.append(item)
      refreshIndices()
    }
  }

  Component.onCompleted: {
    if (flowData && flowData.steps) {
      for (var i = 0; i < flowData.steps.length; i++) {
        var step = flowData.steps[i]
        var initData = {
          "stepId": step.id || generateId(step["type"]),
          "conditionsArray": step["if"] || [],
          "gotoTarget": step.goto || "",
          "gotoAltTarget": step.goto_alt || ""
        }

        if (step.type === "action") {
          var pArray = []
          if (step.params) {
            for (var k in step.params) {
              var val = step.params[k]
              var valType = typeof val === "boolean" ? "bool" : (typeof val === "number" ? "number" : "string")
              pArray.push({"key": k, "type": valType, "value": String(val)})
            }
          }
          initData.targetType =  step["function"] ? "function" : "action"
          initData.actionId = step["action"] || ""
          initData.functionId = step["function"] || ""
          initData.paramsArray = pArray
        } else if (step.type === "wait") {
          var dur = (step.params && step.params.duration) ? step.params.duration : "1s"
          initData.paramsArray = [{ "key": "duration", "type": "string", "value": String(dur) }]
        } else if (step.type === "throttle") {
          var pArray = []
          if (step.params) {
            for (var k in step.params) {
              pArray.push({"key": k, "type": "array", "value": step.params[k]})
            }
          }
          initData.paramsArray = pArray
        } else if (step.type === "round") {
          var pArray = []
          if (step.params) {
            for (var k in step.params) {
              pArray.push({"key": k, "type": "array", "value": step.params[k]})
            }
          }
          initData.paramsArray = pArray
        } else if (step.type === "math") {
          var pArray = []
          if (step.params) {
            for (var k in step.params) {
              pArray.push({"key": k, "type": "array", "value": step.params[k]})
            }
          }
          initData.paramsArray = pArray
        } else if (step.type === "get") {
          initData.sourceId = step["source"] || ""
          initData.functionId = step["function"] || ""
          
          var getPArray = []
          if (step.params) {
            for (var gk in step.params) {
              var gVal = step.params[gk]
              var gType = typeof gVal === "boolean" ? "bool" : (typeof gVal === "number" ? "number" : "string")
              getPArray.push({"key": gk, "type": gType, "value": String(gVal)})
            }
          }
          initData.paramsArray = getPArray
        } else if (step.type === "string") {
          initData.functionId = step["function"] || ""
          
          var getPArray = []
          if (step.params) {
            for (var gk in step.params) {
              var gVal = step.params[gk]
              var gType = typeof gVal === "boolean" ? "bool" : (typeof gVal === "number" ? "number" : "string")
              getPArray.push({"key": gk, "type": gType, "value": String(gVal)})
            }
          }
          initData.paramsArray = getPArray
        } 

        createStepUI(step.type, initData)
      }
    }
  }

  SilicaFlickable {
    anchors.fill: parent
    contentHeight: column.height

    PullDownMenu {
       MenuItem {
        text: "Add String Function"
        onClicked: createStepUI("string", {"stepId": generateId("string"), "conditionsArray": [], "gotoTarget": "", "gotoAltTarget": "end", "paramsArray": []})
      }
      MenuItem {
        text: "Add Throttle"
        onClicked: createStepUI("throttle", {"stepId": generateId("throttle"), "conditionsArray": [], "gotoTarget": "", "gotoAltTarget": "end", "paramsArray": [{ "key": "duration", "type": "string", "value": "1s" }, { "key": "scope", "type": "array", "value": [] }]})
      }
      MenuItem {
        text: "Add Round"
        onClicked: createStepUI("round", {"stepId": generateId("round"), "conditionsArray": [], "gotoTarget": "", "gotoAltTarget": "end", "paramsArray": []})
      }
      MenuItem {
        text: "Add Math"
        onClicked: createStepUI("math", {"stepId": generateId("math"), "conditionsArray": [], "gotoTarget": "", "gotoAltTarget": "end", "paramsArray": []})
      }
      MenuItem {
        text: "Add Action"
        onClicked: createStepUI("action", {"stepId": generateId("action"), "conditionsArray": [], "gotoTarget": "", "gotoAltTarget": "end"})
      }
      MenuItem {
        text: "Add Wait"
        onClicked: createStepUI("wait", {"stepId": generateId("wait"), "conditionsArray": [], "gotoTarget": "", "gotoAltTarget": "end", "paramsArray": [{ "key": "duration", "type": "string", "value": "1s" }]})
      }
      MenuItem {
        text: "Add Get"
        onClicked: createStepUI("get", {"stepId": generateId("get"), "conditionsArray": [], "gotoTarget": "", "gotoAltTarget": "end"})
      }
      MenuItem {
        text: "Add Branch"
        onClicked: createStepUI("branch", {"stepId": generateId("branch"), "conditionsArray": [], "gotoTarget": "", "gotoAltTarget": "end", "paramsArray": []})
      }
    }

    Column {
      id: column
      width: parent.width
      spacing: 8

      DialogHeader {  }

      TextSwitch {
        text: "Enabled"
        checked: root.editedEnabled
        onCheckedChanged: root.editedEnabled = checked
      }

      TextField {
        width: parent.width
        label: "Flow Name"
        text: root.editedName
        font.pixelSize: Theme.fontSizeMedium
        onTextChanged: root.editedName = text
      }

      SectionHeader { text: "Triggers" }

      Repeater {
        model: root.editedTriggers
        delegate: ListItem {
          width: parent.width
          Label {
            anchors.left: parent.left; 
            anchors.leftMargin: Theme.paddingMedium
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: Theme.fontSizeMedium
            text: {
              for (var i = 0; i < app.data_sources.length; i++) {
                if (app.data_sources[i].id === modelData) {
                  return app.data_sources[i].name
                }
              }
              return "[Trigger not found]"
            }
            color: Theme.primaryColor
          }
          IconButton {
            icon.source: "image://theme/icon-m-clear"
            anchors.right: parent.right; 
            onClicked: {
              var tmp = root.editedTriggers.slice()
              tmp.splice(index, 1)
              root.editedTriggers = tmp
            }
          }
        }
      }

      Button {
        text: "Add Trigger"
        preferredWidth: Theme.buttonWidthSmall
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Theme.paddingSmall
        onClicked: {
          var picker = pageStack.push("TriggerPickerPage.qml", { "existing": root.editedTriggers })
          picker.sourceSelected.connect(function(sourceId) {
            var tmp = root.editedTriggers.slice()
            if (tmp.indexOf(sourceId) === -1) {
              tmp.push(sourceId)
              root.editedTriggers = tmp
            }
          })
        }
      }

      SectionHeader { text: "Logic Steps" }

      Repeater { 
        model: uiStepsModel 
      }

      Item { width: 1; height: Theme.paddingLarge }
    }
  }

  onAccepted: {
    var finalSteps = []
    for (var i = 0; i < uiStepsModel.count; i++) {
      var uiItem = uiStepsModel.get(i)
      var stepPayload = {
        "id": uiItem.stepId,
        "type": uiItem.stepType
      }
      if (uiItem.conditionsArray && uiItem.conditionsArray.length > 0) {
        stepPayload["if"] = uiItem.conditionsArray
      }
      if (uiItem.gotoTarget !== "") {
        stepPayload.goto = uiItem.gotoTarget
      }
      if (uiItem.gotoAltTarget !== undefined && uiItem.gotoAltTarget !== "") {
        stepPayload.goto_alt = uiItem.gotoAltTarget
      }
      if (uiItem.stepType === "action") {
        if (uiItem.targetType === "function") {
          stepPayload.function = uiItem.functionId
        } else {
          stepPayload.action = uiItem.actionId
        }
      }
      if (uiItem.stepType === "get") {
        if (uiItem.functionId !== "") {
          stepPayload.function = uiItem.functionId
        } else {
          stepPayload.source = uiItem.sourceId
        }
      }
      if (uiItem.stepType === "string") {
        stepPayload.function = uiItem.functionId
      }
      if (uiItem.paramsArray && uiItem.paramsArray.length > 0) {
        var pMap = {}
        for (var p = 0; p < uiItem.paramsArray.length; p++) {
          var param = uiItem.paramsArray[p]
          if (param.type === "number") {
            pMap[param.key] = Number(param.value)
          } else if (param.type === "bool") {
            pMap[param.key] = (param.value === "true" || param.value === true)
          } else {
            pMap[param.key] = param.value
          }
        }
        stepPayload.params = pMap
      }
      finalSteps.push(stepPayload)
    }

    var updatedFlow = {
      "id": flowData ? flowData.id : "new_flow",
      "name": editedName,
      "enabled": root.editedEnabled,
      "triggers": editedTriggers,
      "steps": finalSteps
    }

    updateFlowInList(updatedFlow)
    app.signal_update_flows(app.flows)
  }

  function updateFlowInList(newFlow) {
    var flowsCopy = app.flows
    var found = false
    for (var i = 0; i < flowsCopy.length; i++) {
      if (flowsCopy[i].id === newFlow.id) {
        flowsCopy[i] = newFlow
        found = true
        break
      }
    }
    if (!found) {
      flowsCopy.push(newFlow)
    }
    app.flows = flowsCopy
  }
}
