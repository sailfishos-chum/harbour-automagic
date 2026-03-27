import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
  id: root

  property var actionData: ({})
  property string editedType: actionData.type || ""
  property string editedName: actionData.name || ""
  property bool editedEnabled: actionData.enabled !== undefined ? actionData.enabled : true
  
  property var currentTemplate: null
  property var formValues: ({})

  ListModel { id: argsModel }
  ListModel { id: paramsModel }

  canAccept: nameField.text.trim().length > 0

  SilicaFlickable {
    anchors.fill: parent
    contentHeight: mainColumn.height

    Column {
      id: mainColumn
      width: parent.width
      spacing: Theme.paddingMedium

      DialogHeader { title: currentTemplate ? currentTemplate.name : "Edit Action" }

      TextField {
        id: nameField
        width: parent.width
        label: "Action Name"
        text: root.editedName
        onTextChanged: root.editedName = text
      }

      TextSwitch {
        text: "Enabled"
        checked: root.editedEnabled
        onCheckedChanged: root.editedEnabled = checked
      }

      ComboBox {
        width: parent.width
        label: "Action Type"
        value: root.editedType.toUpperCase()
        menu: ContextMenu {
          MenuItem { text: "LOG"; onClicked: root.editedType = "log" }
          MenuItem { text: "SHELL"; onClicked: root.editedType = "shell" }
          MenuItem { text: "HTTP"; onClicked: root.editedType = "http" }
          MenuItem { text: "MQTT_PUBLISH"; onClicked: root.editedType = "mqtt_publish" }
          MenuItem { text: "DBUS_METHOD"; onClicked: root.editedType = "dbus_method" }
          MenuItem { text: "SQLITE_QUERY"; onClicked: root.editedType = "sqlite_query" }
          MenuItem { text: "MYSQL_QUERY"; onClicked: root.editedType = "mysql_query" }
          MenuItem { text: "SMTP"; onClicked: root.editedType = "smtp" }
          MenuItem { text: "IMAP_MARK_SEEN"; onClicked: root.editedType = "imap_mark_seen" }
        }
        onValueChanged: {
          if (app.templates && app.templates.ui_schema && app.templates.ui_schema.action_types[root.editedType]) {
            root.currentTemplate = app.templates.ui_schema.action_types[root.editedType]
            var vals = {}
            for (var i = 0; i < root.currentTemplate.fields.length; i++) {
              var field = root.currentTemplate.fields[i]
              var val = root.actionData[field.key]
              
              if (val === undefined || val === "") {
                val = field.default !== undefined ? field.default : (field.ui_type === "boolean" ? false : "")
              }
              if (field.ui_type === "boolean") {
                val = (val === true || String(val).toLowerCase() === "true")
              }
              vals[field.key] = val
            }
            root.formValues = vals
          } else {
            root.currentTemplate = null
          }
        }
      }

      Repeater {
        model: currentTemplate ? currentTemplate.fields : []
        delegate: DynamicSchemaField {
          width: parent.width
          fieldSchema: modelData
          labelText: modelData.label
          currentValue: root.formValues[modelData.key] !== undefined ? String(root.formValues[modelData.key]) : ""
          onValueChanged: {
            var temp = root.formValues
            temp[modelData.key] = newValue
            root.formValues = temp
          }
        }
      }

      Item { 
        width: 1; height: Theme.paddingMedium 
        visible: root.editedType === "dbus_method"
      }
      
      DbusArgsEditor {
        visible: root.editedType === "dbus_method"
        argsModel: argsModel
      }

      Item { 
        width: 1; height: Theme.paddingMedium 
        visible: root.editedType !== "dbus_method"
      }
      
      SectionHeader { 
        text: "Custom Parameters"
        visible: root.editedType !== "dbus_method"
      }

      Repeater {
        model: root.editedType !== "dbus_method" ? paramsModel : null
        delegate: Column {
          width: parent.width
          Row {
            width: parent.width
            TextField {
              width: parent.width - delParamBtn.width
              label: "Key"
              text: model.pKey
              onTextChanged: if (focus) paramsModel.setProperty(index, "pKey", text)
            }
            IconButton {
              id: delParamBtn
              icon.source: "image://theme/icon-m-clear"
              onClicked: paramsModel.remove(index)
              anchors.verticalCenter: parent.verticalCenter
            }
          }
          TextArea {
            width: parent.width
            label: "Value"
            text: model.pValue
            onTextChanged: if (focus) paramsModel.setProperty(index, "pValue", text)
          }
          Separator { width: parent.width; color: Theme.primaryColor; opacity: 0.5 }
        }
      }

      Button {
        text: "Add Parameter"
        visible: root.editedType !== "dbus_method"
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: paramsModel.append({ "pKey": "", "pValue": "" })
      }

      Item { width: 1; height: Theme.paddingLarge }
    }
  }

  Component.onCompleted: {
    if (!actionData.id) {
      actionData.id = "action_" + Math.random().toString(36).substr(2, 9)
    }

    if (actionData.type == "sqlite_query" && !actionData.query && actionData.payload != "") {
      actionData.query = actionData.payload
      delete actionData.payload
    }
    if (actionData.type == "sqlite_query" && !actionData.path && actionData.address != "") {
      actionData.path = actionData.address
      delete actionData.address
    }

    if (app.templates && app.templates.ui_schema && app.templates.ui_schema.action_types[editedType]) {
      currentTemplate = app.templates.ui_schema.action_types[editedType]
    }

    var vals = {}
    if (currentTemplate) {
      for (var i = 0; i < currentTemplate.fields.length; i++) {
        var field = currentTemplate.fields[i]
        var val = actionData[field.key]
        
        if (val === undefined || val === "") {
          val = field.default !== undefined ? field.default : (field.ui_type === "boolean" ? false : "")
        }
        if (field.ui_type === "boolean") {
          val = (val === true || String(val).toLowerCase() === "true")
        }
        vals[field.key] = val
      }
    }
    root.formValues = vals

    if (actionData.args) {
      for (var j = 0; j < actionData.args.length; j++) {
        var arg = actionData.args[j]
        var v = arg.value
        if (v !== null && typeof v === "object") v = JSON.stringify(v)
        argsModel.append({ "aType": arg.type || "s", "aValue": v !== undefined ? String(v) : "" })
      }
    }
    
    if (actionData.params) {
      for (var pk in actionData.params) {
        paramsModel.append({ "pKey": pk, "pValue": String(actionData.params[pk]) })
      }
    }
  }

  onAccepted: {
    actionData.name = root.editedName
    actionData.type = root.editedType
    actionData.enabled = root.editedEnabled

    for (var k in root.formValues) {
      var val = root.formValues[k]
      
      if (root.currentTemplate) {
        for (var f = 0; f < root.currentTemplate.fields.length; f++) {
          if (root.currentTemplate.fields[f].key === k && root.currentTemplate.fields[f].ui_type === "boolean") {
            val = (val === true || String(val).toLowerCase() === "true")
            break
          }
        }
      }
      actionData[k] = val
    }

    if (root.editedType === "dbus_method") {
      var aArr = []
      for (var i = 0; i < argsModel.count; i++) {
        var arg = argsModel.get(i)
        var valArg = arg.aValue
        if (arg.aType === "u" || arg.aType === "i") {
          valArg = parseInt(valArg) || 0
        } else if (arg.aType === "b") {
          valArg = (valArg.toLowerCase() === "true" || valArg === "1")
        } else if (arg.aType.indexOf("a") === 0 || arg.aType.indexOf("{") !== -1) {
          try {
            if (valArg.trim().indexOf("[") === 0 || valArg.trim().indexOf("{") === 0) {
              valArg = JSON.parse(valArg)
            }
          } catch (e) {}
        }
        aArr.push({ "type": arg.aType, "value": valArg })
      }
      actionData.args = aArr
      delete actionData.params
    } else {
      var pMap = {}
      for (var pIdx = 0; pIdx < paramsModel.count; pIdx++) {
        var p = paramsModel.get(pIdx)
        if (p.pKey.trim() !== "") pMap[p.pKey] = p.pValue
      }
      actionData.params = pMap
      delete actionData.args
    }
  }
}
