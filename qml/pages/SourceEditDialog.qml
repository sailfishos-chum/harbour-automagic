import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
  id: root

  property var sourceData: ({})
  property string editedId: sourceData.id || ""
  property string editedName: sourceData.name || ""
  property string editedType: sourceData.type || "file"
  property bool editedIsTrigger: !!sourceData.trigger
  property bool editedEnabled: sourceData.enabled !== undefined ? sourceData.enabled : true
  
  property var currentTemplate: null
  property var formValues: ({})

  ListModel { id: filterModel }
  ListModel { id: transformModel }
  ListModel { id: argsModel }

  canAccept: nameField.text.trim().length > 0

  SilicaFlickable {
    anchors.fill: parent
    contentHeight: column.height

    Column {
      id: column
      width: parent.width
      spacing: Theme.paddingSmall

      DialogHeader { title: root.editedId ? "Edit Source" : "New Source" }

      TextSwitch {
        text: "Enabled"
        checked: root.editedEnabled
        onCheckedChanged: root.editedEnabled = checked
      }

      TextField {
        id: nameField
        width: parent.width
        label: "Name"
        text: root.editedName
        onTextChanged: root.editedName = text
      }

      TextSwitch {
        text: "Act as Trigger"
        
        checked: {
          if (root.currentTemplate) {
            if (root.currentTemplate.trigger_mode === "always") return true;
            if (root.currentTemplate.trigger_mode === "never") return false;
          }
          return root.editedIsTrigger;
        }
        
        enabled: !root.currentTemplate || (root.currentTemplate.trigger_mode !== "always" && root.currentTemplate.trigger_mode !== "never")
        
        description: {
          if (!enabled && root.currentTemplate) {
            if (root.currentTemplate.trigger_mode === "always") return "This source type must be a trigger."
            if (root.currentTemplate.trigger_mode === "never") return "This source type cannot be a trigger."
          }
          return ""
        }

        onCheckedChanged: {
          if (enabled) {
            root.editedIsTrigger = checked
          }
        }
      }

      ComboBox {
        width: parent.width
        label: "Protocol"
        value: root.editedType.toUpperCase()
        menu: ContextMenu {
          MenuItem { text: "FILE"; onClicked: root.editedType = "file" }
          MenuItem { text: "SQLITE"; onClicked: root.editedType = "sqlite" }
          MenuItem { text: "MYSQL"; onClicked: root.editedType = "mysql" }
          MenuItem { text: "MQTT"; onClicked: root.editedType = "mqtt" }
          MenuItem { text: "HTTP"; onClicked: root.editedType = "http" }
          MenuItem { text: "DBUS"; onClicked: root.editedType = "dbus" }
          MenuItem { text: "TIMER"; onClicked: root.editedType = "timer" }
          MenuItem { text: "STATE"; onClicked: root.editedType = "state" }
          MenuItem { text: "IMAP"; onClicked: root.editedType = "imap" }
          MenuItem { text: "LOCATION"; onClicked: root.editedType = "location" }
        }
        onValueChanged: {
          if (app.templates && app.templates.ui_schema && app.templates.ui_schema.source_types[root.editedType]) {
            root.currentTemplate = app.templates.ui_schema.source_types[root.editedType]
            var vals = {}
            for (var i = 0; i < root.currentTemplate.fields.length; i++) {
              var field = root.currentTemplate.fields[i]
              var val = root.sourceData[field.key]
              
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

      DbusArgsEditor {
        visible: root.editedType === "dbus"
        argsModel: argsModel
      }

      SectionHeader { 
        text: String(currentTemplate.output_label)
        visible: Boolean(currentTemplate.output_label) 
      }

      Label {
        width: parent.width - Theme.paddingMedium
        text: Boolean(currentTemplate.output_hint) ? String(currentTemplate.output_hint) : ""
        font.pixelSize: Theme.fontSizeExtraSmall
        wrapMode: Text.WordWrap
        color: Theme.secondaryColor
        x: Theme.paddingMedium
      }

      SectionHeader { text: "Filters" }

      Repeater {
        model: filterModel
        delegate: Column {
          width: parent.width
          Row {
            width: parent.width
            TextField {
              width: parent.width - deleteFilterBtn.width
              label: "Key"
              text: model.fKey
              inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
              onTextChanged: if (focus) filterModel.setProperty(index, "fKey", text)
            }
            IconButton {
              id: deleteFilterBtn
              icon.source: "image://theme/icon-m-clear"
              anchors.verticalCenter: parent.verticalCenter
              onClicked: filterModel.remove(index)
            }
          }
          TextField {
            width: parent.width
            label: "Value"
            text: model.fValue
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
            onTextChanged: if (focus) filterModel.setProperty(index, "fValue", text)
          }
          Separator { width: parent.width; color: Theme.primaryColor; opacity: 0.8 }
        }
      }

      Button {
        text: "Add Filter"
        anchors.horizontalCenter: parent.horizontalCenter
        preferredWidth: Theme.buttonWidthSmall
        onClicked: filterModel.append({"fKey": "", "fValue": ""})
      }

      SectionHeader { text: "Transformations" }
      Repeater {
        model: transformModel
        delegate: Column {
          width: parent.width
          Item {
            width: parent.width; height: ttype_cbox.height
            ComboBox {
              id: ttype_cbox
              width: parent.width - deleteTransformBtn.width - optional_switch.width
              label: "Type"; value: model.tType
              menu: ContextMenu {
                MenuItem { text: "copy"; onClicked: transformModel.setProperty(index, "tType", "copy") }
                MenuItem { text: "template"; onClicked: transformModel.setProperty(index, "tType", "template") }
                MenuItem { text: "value_map"; onClicked: transformModel.setProperty(index, "tType", "value_map") }
                MenuItem { text: "math"; onClicked: transformModel.setProperty(index, "tType", "math") }
                MenuItem { text: "round"; onClicked: transformModel.setProperty(index, "tType", "round") }
                MenuItem { text: "uppercase"; onClicked: transformModel.setProperty(index, "tType", "uppercase") }
                MenuItem { text: "lowercase"; onClicked: transformModel.setProperty(index, "tType", "lowercase") }
                MenuItem { text: "trim"; onClicked: transformModel.setProperty(index, "tType", "trim") }
                MenuItem { text: "replace"; onClicked: transformModel.setProperty(index, "tType", "replace") }
                MenuItem { text: "regex_replace"; onClicked: transformModel.setProperty(index, "tType", "regex_replace") }
              }
            }
            TextSwitch {
              id: optional_switch; width: deleteTransformBtn.width * 2.5
              text: "Opt."; checked: model.tOptional
              onCheckedChanged: transformModel.setProperty(index, "tOptional", checked)
              anchors { right: parent.right; verticalCenter: ttype_cbox.verticalCenter }
            }
            IconButton {
              id: deleteTransformBtn; icon.source: "image://theme/icon-m-clear"
              onClicked: transformModel.remove(index)
              anchors { verticalCenter: ttype_cbox.verticalCenter; right: parent.right }
            }
          }
          TextField {
            width: parent.width; label: "Input Variable"; text: model.tIn
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
            onTextChanged: if (focus) transformModel.setProperty(index, "tIn", text)
          }
          TextField {
            width: parent.width; label: "Output Variable"; text: model.tOut
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
            onTextChanged: if (focus) transformModel.setProperty(index, "tOut", text)
          }
          TextField {
            width: parent.width; visible: model.tType === "value_map"
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
            label: "Map Name"; text: model.tMap
            onTextChanged: if (focus) transformModel.setProperty(index, "tMap", text)
          }
          TextField {
            width: parent.width; visible: model.tType === "round"
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
            label: "Decimal Places"; text: String(model.tDecimal)
            onTextChanged: if (focus) transformModel.setProperty(index, "tDecimal", parseInt(text) || 0)
          }
          TextField {
            width: parent.width
            visible: model.tType === "replace"
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
            label: "Search"
            text: model.tSearch
            onTextChanged: if (focus) transformModel.setProperty(index, "tSearch", text)
          }
          TextField {
            width: parent.width
            visible: model.tType === "regex_replace"
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
            label: "Pattern"
            text: model.tPattern
            onTextChanged: if (focus) transformModel.setProperty(index, "tPattern", text)
          }
          TextField {
            width: parent.width
            visible: model.tType === "replace" || model.tType === "regex_replace"
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
            label: "Replace"
            text: model.tReplace
            onTextChanged: if (focus) transformModel.setProperty(index, "tReplace", text)
          }
          Separator { width: parent.width; color: Theme.primaryColor; opacity: 0.8 }
        }
      }
      Button {
        text: "Add Transformation"
        anchors.horizontalCenter: parent.horizontalCenter
        preferredWidth: Theme.buttonWidthSmall
        onClicked: transformModel.append({ "tType": "copy", "tIn": "", "tOut": "", "tMap": "", "tOptional": false, "tDecimal": 0 })
      }
      Item { width: 1; height: Theme.paddingLarge }
    }
  }

  Component.onCompleted: {
    if (!sourceData.id) {
      sourceData.id = "source_" + Math.random().toString(36).substr(2, 9)
    }

    if (sourceData.type == "sqlite" && !sourceData.query && sourceData.pattern != "") {
      sourceData.query = sourceData.pattern
      delete sourceData.pattern
    }

    if (sourceData.type == "sqlite" && !sourceData.path && sourceData.address != "") {
      sourceData.path = sourceData.address
      delete sourceData.address
    }

    if (app.templates && app.templates.ui_schema && app.templates.ui_schema.source_types[editedType]) {
      currentTemplate = app.templates.ui_schema.source_types[editedType]
    }

    var vals = {}
    if (currentTemplate) {
      for (var i = 0; i < currentTemplate.fields.length; i++) {
        var field = currentTemplate.fields[i]
        var val = sourceData[field.key]
        
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

    if (sourceData.filters) {
      for (var fk in sourceData.filters) {
        filterModel.append({"fKey": fk, "fValue": sourceData.filters[fk]})
      }
    }

    if (sourceData.transformations) {
      for (var t = 0; t < sourceData.transformations.length; t++) {
        var tr = sourceData.transformations[t]
        transformModel.append({
          "tType": tr.type || "copy",
          "tIn": tr["in"] || "",
          "tOut": tr.out || "",
          "tMap": tr.map || "",
          "tOptional": tr.optional || false,
          "tDecimal": tr.decimal_places || 0,
          "tReplace": tr.replace || "",
          "tSearch": tr.search || "",
          "tPattern": tr.pattern || ""
        })
      }
    }

    if (sourceData.args && editedType === "dbus") {
      for (var j = 0; j < sourceData.args.length; j++) {
        var arg = sourceData.args[j]
        var v = arg.value
        if (v !== null && typeof v === "object") v = JSON.stringify(v)
        argsModel.append({
          "aType": (arg.type === "string" ? "s" : arg.type) || "s",
          "aValue": v !== undefined ? String(v) : ""
        })
      }
    }
  }

  onAccepted: {
    sourceData.name = root.editedName
    sourceData.type = root.editedType
    sourceData.enabled = root.editedEnabled

    if (root.currentTemplate && root.currentTemplate.trigger_mode === "always") {
      sourceData.trigger = true
    } else if (root.currentTemplate && root.currentTemplate.trigger_mode === "never") {
      sourceData.trigger = false
    } else {
      sourceData.trigger = root.editedIsTrigger
    }

    for (var k in root.formValues) {
      var val = root.formValues[k]
      
      if (root.currentTemplate) {
        for (var f = 0; f < root.currentTemplate.fields.length; f++) {
          if (root.currentTemplate.fields[f].key === k) {
            var uiType = root.currentTemplate.fields[f].ui_type
            
            if (uiType === "boolean") {
              val = (val === true || String(val).toLowerCase() === "true")
            } else if (uiType === "array" || uiType === "array_integer") {
              var arr = []
              var strVal = Array.isArray(val) ? val.join(",") : String(val || "")
              var parts = strVal.split(",")
              
              for (var p = 0; p < parts.length; p++) {
                var trimmed = parts[p].trim()
                if (trimmed !== "") {
                  if (uiType === "array_integer") {
                    var pInt = parseInt(trimmed, 10)
                    if (!isNaN(pInt)) arr.push(pInt)
                  } else {
                    arr.push(trimmed)
                  }
                }
              }
              val = arr.length > 0 ? arr : undefined
            }
            break
          }
        }
      }

      if (val !== undefined) {
        sourceData[k] = val
      } else {
        delete sourceData[k]
      }
    }

    if (root.editedType === "dbus") {
      var aArr = []
      for (var i = 0; i < argsModel.count; i++) {
        var arg = argsModel.get(i)
        var valArg = arg.aValue
        if (arg.aType === "u" || arg.aType === "i") valArg = parseInt(valArg) || 0
        else if (arg.aType === "b") valArg = (valArg.toLowerCase() === "true" || valArg === "1")
        else {
          try { if (valArg.indexOf("[") === 0 || valArg.indexOf("{") === 0) valArg = JSON.parse(valArg) } catch (e) {}
        }
        aArr.push({ "type": arg.aType || "s", "value": valArg })
      }
      sourceData.args = aArr
    }

    var fMap = {}
    for (var fj = 0; fj < filterModel.count; fj++) {
      var f = filterModel.get(fj)
      if (f.fKey.trim() !== "") fMap[f.fKey.trim()] = f.fValue
    }
    sourceData.filters = Object.keys(fMap).length > 0 ? fMap : undefined

    var tArr = []
    for (var tk = 0; tk < transformModel.count; tk++) {
      var tm = transformModel.get(tk)
      var tObj = { "type": tm.tType, "in": tm.tIn, "out": tm.tOut }
      if (tm.tType === "value_map") tObj.map = tm.tMap
      if (tm.tType === "round") tObj.decimal_places = tm.tDecimal
      if (tm.tOptional) tObj.optional = true
      if (tm.tType === "replace") {
        tObj.search = tm.tSearch
        tObj.replace = tm.tReplace
      }
      if (tm.tType === "regex_replace") {
        tObj.pattern = tm.tPattern
        tObj.replace = tm.tReplace
      }
      tArr.push(tObj)
    }
    sourceData.transformations = tArr.length > 0 ? tArr : undefined
  }
}
