import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
  id: page

  property var examples: []
  property bool loading: true

  SilicaListView {
    anchors.fill: parent
    model: page.examples

    header: PageHeader {
      title: "Examples Library"
    }

    delegate: ListItem {
      id: delegate
      contentHeight: layout.height + Theme.paddingMedium
      
      Column {
        id: layout
        anchors {
          left: parent.left
          right: parent.right
          leftMargin: Theme.horizontalPageMargin
          rightMargin: Theme.horizontalPageMargin
          verticalCenter: parent.verticalCenter
        }

        Label {
          text: modelData.name
          color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
          width: parent.width
          truncationMode: TruncationMode.Fade
        }

        Label {
          text: modelData.description || "Automation template"
          font.pixelSize: Theme.fontSizeExtraSmall
          color: Theme.secondaryColor
          width: parent.width
          wrapMode: Text.WordWrap // Added wrapping
          maximumLineCount: 3
        }

        Row {
          spacing: Theme.paddingSmall
          anchors.topMargin: Theme.paddingSmall
          visible: !!modelData.data_sources || !!modelData.actions || !!modelData.flows || !!modelData.value_maps

          Rectangle {
            visible: !!modelData.data_sources
            width: sourceLabel.width + Theme.paddingMedium
            height: sourceLabel.height + Theme.paddingSmall
            color: Theme.rgba(Theme.primaryColor, 0.1)
            opacity: 0.5
            radius: Theme.paddingSmall / 2
            Label {
              id: sourceLabel
              anchors.centerIn: parent
              text: "Source"
              font.pixelSize: Theme.fontSizeExtraSmall
              color: Theme.primaryColor
            }
          }

          Rectangle {
            visible: !!modelData.actions
            width: actionLabel.width + Theme.paddingMedium
            height: actionLabel.height + Theme.paddingSmall
            color: Theme.rgba(Theme.primaryColor, 0.1)
            opacity: 0.5
            radius: Theme.paddingSmall / 2
            Label {
              id: actionLabel
              anchors.centerIn: parent
              text: "Action"
              font.pixelSize: Theme.fontSizeExtraSmall
              color: Theme.primaryColor
            }
          }

          Rectangle {
            visible: !!modelData.flows
            width: flowLabel.width + Theme.paddingMedium
            height: flowLabel.height + Theme.paddingSmall
            color: Theme.rgba(Theme.primaryColor, 0.1)
            opacity: 0.5
            radius: Theme.paddingSmall / 2
            Label {
              id: flowLabel
              anchors.centerIn: parent
              text: "Flow"
              font.pixelSize: Theme.fontSizeExtraSmall
              color: Theme.primaryColor
            }
          }

          Rectangle {
            visible: !!modelData.value_maps
            width: mapLabel.width + Theme.paddingMedium
            height: mapLabel.height + Theme.paddingSmall
            color: Theme.rgba(Theme.primaryColor, 0.1)
            opacity: 0.5
            radius: Theme.paddingSmall / 2
            Label {
              id: mapLabel
              anchors.centerIn: parent
              text: "Value Maps"
              font.pixelSize: Theme.fontSizeExtraSmall
              color: Theme.primaryColor
            }
          }
        }
      }

      Separator {
        anchors.bottom: parent.bottom
        color: Theme.secondaryColor
        horizontalAlignment: Qt.AlignHCenter
        width: parent.width
        opacity: 0.5
      }

      menu: ContextMenu {
        MenuItem {
          text: "Import"
          onClicked: importExample(modelData)
        }
      }
    }

    ViewPlaceholder {
      enabled: page.loading
      text: "Fetching library..."
    }

    PullDownMenu {
      MenuItem {
        text: "Refresh"
        onClicked: fetchLibrary()
      }
    }
  }

  function fetchLibrary() {
    page.loading = true
    var xhr = new XMLHttpRequest()
    xhr.onreadystatechange = function() {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        page.loading = false
        if (xhr.status === 200) {
          try {
            var raw = JSON.parse(xhr.responseText)
            var valid = []
            for (var i = 0; i < raw.length; i++) {
              if (raw[i].name) {
                valid.push(raw[i])
              }
            }
            page.examples = valid
          } catch (e) {
            app.signal_error('LibraryPage', "fetchLibrary", "Error parsing library data.")
          }
        } else {
          app.signal_error('LibraryPage', "fetchLibrary", "Could not connect to library server (Status: " + xhr.status + ")")
        }
      }
    }
    xhr.open("GET", "https://qml.app/automagic/examples.php")
    xhr.send()
  }

  function importExample(example) {
    var data = {
      flows:        (example.flows        && example.flows.data)        ? example.flows.data        : [],
      data_sources: (example.data_sources && example.data_sources.data) ? example.data_sources.data : [],
      actions:      (example.actions      && example.actions.data)      ? example.actions.data      : [],
      value_maps:   (example.value_maps   && example.value_maps.data)   ? example.value_maps.data   : {}
    }

    var conflicts = _findConflicts(data)

    if (conflicts.length > 0) {
      var dialog = pageStack.push(Qt.resolvedUrl("ConflictDialog.qml"), {
        "importData": data,
        "conflictList": conflicts
      })
      dialog.accepted.connect(function() {
        _applyImport(dialog.importData, true)
      })
    } else {
      _applyImport(data, false)
    }
  }

  function _findConflicts(data) {
    var conflicts = []

    var flows = data.flows || []
    for (var i = 0; i < flows.length; i++)
      for (var fi = 0; fi < app.flows.length; fi++)
        if (app.flows[fi].id === flows[i].id) { conflicts.push("Flow: " + (flows[i].name || flows[i].id)); break }

    var sources = data.data_sources || []
    for (var j = 0; j < sources.length; j++)
      for (var si = 0; si < app.data_sources.length; si++)
        if (app.data_sources[si].id === sources[j].id) { conflicts.push("Source: " + (sources[j].name || sources[j].id)); break }

    var actions = data.actions || []
    for (var k = 0; k < actions.length; k++)
      for (var ai = 0; ai < app.actions.length; ai++)
        if (app.actions[ai].id === actions[k].id) { conflicts.push("Action: " + (actions[k].name || actions[k].id)); break }

    var maps = data.value_maps || {}
    for (var key in maps)
      if (app.value_maps[key] !== undefined) conflicts.push("Value Map: " + key)

    return conflicts
  }

  function _applyImport(data, overwrite) {
    var flows = data.flows || []
    var sources = data.data_sources || []
    var actions = data.actions || []
    var maps = data.value_maps || {}

    if (flows.length > 0) {
      var flwList = app.flows
      for (var i = 0; i < flows.length; i++) {
        if (overwrite)
          for (var fi = flwList.length - 1; fi >= 0; fi--)
            if (flwList[fi].id === flows[i].id) { flwList.splice(fi, 1); break }
        flwList.push(flows[i])
      }
      app.flows = []; app.flows = flwList
      python.save_flows()
    }

    if (sources.length > 0) {
      var srcList = app.data_sources
      for (var j = 0; j < sources.length; j++) {
        if (overwrite)
          for (var si = srcList.length - 1; si >= 0; si--)
            if (srcList[si].id === sources[j].id) { srcList.splice(si, 1); break }
        srcList.push(sources[j])
      }
      app.data_sources = []; app.data_sources = srcList
      python.save_data_sources()
    }

    if (actions.length > 0) {
      var actList = app.actions
      for (var k = 0; k < actions.length; k++) {
        if (overwrite)
          for (var ai = actList.length - 1; ai >= 0; ai--)
            if (actList[ai].id === actions[k].id) { actList.splice(ai, 1); break }
        actList.push(actions[k])
      }
      app.actions = []; app.actions = actList
      python.save_actions()
    }

    if (Object.keys(maps).length > 0) {
      var currentMaps = app.value_maps
      for (var key in maps) currentMaps[key] = maps[key]
      app.value_maps = {}; app.value_maps = currentMaps
      python.save_value_maps()
    }

    python.load_data()
  }

  Component.onCompleted: fetchLibrary()
}
