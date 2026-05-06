import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0

Page {
  id: import_page

  property string selectedFolder: ""
  property bool noImportFiles: false
  property var itemList: []

  SilicaFlickable {
    anchors.fill: parent
    contentHeight: column.height

    Column {
      id: column
      width: parent.width

      PageHeader { title: "Import" }

      ValueButton {
        width: parent.width
        label: "Folder"
        value: selectedFolder || "Select Import Folder"
        onClicked: pageStack.push(folderPickerComponent)
      }

      Item { width: parent.width; height: Theme.paddingLarge }

      Button {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Import"
        enabled: selectedFolder.length > 0 && noImportFiles == false
        onClicked: loadAndImport()
      }

      Item { width: parent.width; height: Theme.paddingLarge }

      Label {
        x: Theme.horizontalPageMargin
        visible: noImportFiles
        text: "No files found to import!"
      }

      Label {
        id: name_label
        x: Theme.horizontalPageMargin
        text: ""
        visible: text.length > 0
        color: Theme.primaryColor
        width: parent.width - 2 * Theme.horizontalPageMargin
        truncationMode: TruncationMode.Fade
      }

      Label {
        id: description_label
        x: Theme.horizontalPageMargin
        text: ""
        visible: text.length > 0
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
        width: parent.width - 2 * Theme.horizontalPageMargin
        wrapMode: Text.WordWrap // Added wrapping
        maximumLineCount: 3
      }

      Item { width: parent.width; height: Theme.paddingMedium }

      Repeater {
        model: itemList
        Label {
          width: parent.width - 2 * Theme.horizontalPageMargin
          x: Theme.horizontalPageMargin
          text: "• " + modelData
          color: Theme.primaryColor
          font.pixelSize: Theme.fontSizeSmall
          wrapMode: Text.WordWrap
        }
      }
    }
  }

  Component {
    id: folderPickerComponent
    FolderPickerPage {
      dialogTitle: "Import Folder"
      onSelectedPathChanged: {
        import_page.selectedFolder = selectedPath
        loadAndDisplay()
      }
    }
  }

  function loadAndDisplay() {
    python.call('automagic.automagic_object.load_import_folder', [selectedFolder], function(data) {
      if (!data || Object.keys(data).length === 0) {
        noImportFiles = true;
        name_label.text = ""
        description_label.text = ""
        itemList = [];
        return;
      }
      
      noImportFiles = false;

      if (data.info) {
        name_label.text = data.info.name
        description_label.text = data.info.description
      }

      itemList = listItems(data)
    })
  }

  function loadAndImport() {
    python.call('automagic.automagic_object.load_import_folder', [selectedFolder], function(data) {
      if (!data || Object.keys(data).length === 0) {
        app.signal_error('ImportPage', 'import', 'No importable files found in selected folder')
        return
      }

      var conflicts = findConflicts(data)

      if (conflicts.length > 0) {
        var dialog = pageStack.push(Qt.resolvedUrl("ConflictDialog.qml"), {
          "importData": data,
          "conflictList": conflicts
        })
        dialog.accepted.connect(function() {
          applyImport(dialog.importData, true)
        })
      } else {
        applyImport(data, false)
      }
    })
  }

  function findConflicts(data) {
    var conflicts = []

    var flows = data.flows || []
    for (var i = 0; i < flows.length; i++) {
      for (var fi = 0; fi < app.flows.length; fi++) {
        if (app.flows[fi].id === flows[i].id) {
          conflicts.push("Flow: " + (flows[i].name))
          break
        }
      }
    }

    var sources = data.data_sources || []
    for (var j = 0; j < sources.length; j++) {
      for (var si = 0; si < app.data_sources.length; si++) {
        if (app.data_sources[si].id === sources[j].id) {
          conflicts.push("Source: " + (sources[j].name))
          break
        }
      }
    }

    var actions = data.actions || []
    for (var k = 0; k < actions.length; k++) {
      for (var ai = 0; ai < app.actions.length; ai++) {
        if (app.actions[ai].id === actions[k].id) {
          conflicts.push("Action: " + (actions[k].name))
          break
        }
      }
    }

    var maps = data.value_maps || {}
    for (var key in maps) {
      if (app.value_maps[key] !== undefined) {
        conflicts.push("Value Map: " + key)
      }
    }

    return conflicts
  }

  function listItems(data) {
    var items = []

    var flows = data.flows || []
    for (var i = 0; i < flows.length; i++) {
      items.push("Flow: " + (flows[i].name))
    }

    var sources = data.data_sources || []
    for (var j = 0; j < sources.length; j++) {
      items.push("Source: " + (sources[j].name))
    }

    var actions = data.actions || []
    for (var k = 0; k < actions.length; k++) {
      items.push("Action: " + (actions[k].name))
    }

    var maps = data.value_maps || {}
    for (var key in maps) {
      items.push("Value Map: " + key)
    }

    return items
  }

  function applyImport(data, overwrite) {
    var flows = data.flows || []
    var sources = data.data_sources || []
    var actions = data.actions || []
    var maps = data.value_maps || {}

    if (flows.length > 0) {
      var flwList = app.flows
      for (var i = 0; i < flows.length; i++) {
        if (overwrite) {
          for (var fi = flwList.length - 1; fi >= 0; fi--) {
            if (flwList[fi].id === flows[i].id) { flwList.splice(fi, 1); break }
          }
        }
        flwList.push(flows[i])
      }
      app.flows = []
      app.flows = flwList
      python.save_flows()
    }

    if (sources.length > 0) {
      var srcList = app.data_sources
      for (var j = 0; j < sources.length; j++) {
        if (overwrite) {
          for (var si = srcList.length - 1; si >= 0; si--) {
            if (srcList[si].id === sources[j].id) { srcList.splice(si, 1); break }
          }
        }
        srcList.push(sources[j])
      }
      app.data_sources = []
      app.data_sources = srcList
      python.save_data_sources()
    }

    if (actions.length > 0) {
      var actList = app.actions
      for (var k = 0; k < actions.length; k++) {
        if (overwrite) {
          for (var ai = actList.length - 1; ai >= 0; ai--) {
            if (actList[ai].id === actions[k].id) { actList.splice(ai, 1); break }
          }
        }
        actList.push(actions[k])
      }
      app.actions = []
      app.actions = actList
      python.save_actions()
    }

    if (Object.keys(maps).length > 0) {
      var currentMaps = app.value_maps
      for (var key in maps) {
        currentMaps[key] = maps[key]
      }
      app.value_maps = {}
      app.value_maps = currentMaps
      python.save_value_maps()
    }

    python.load_data()
    pageStack.pop()
  }
}
