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
          text: "Import Example"
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
    var newActions = []
    var newSources = []
    var newFlows = []
    var newValueMaps = {}

    if (example.actions && example.actions.data) {
      for (var i = 0; i < example.actions.data.length; i++) {
        var act = example.actions.data[i]
        var existingName = ""
        for (var a = 0; a < app.actions.length; a++) {
          if (app.actions[a].id === act.id) {
            existingName = app.actions[a].name || app.actions[a].id
            break
          }
        }
        if (existingName !== "") {
          app.signal_error('LibraryPage', "importExample", 'Action already exists as: ' + existingName)
          return
        }
        newActions.push(act)
      }
    }

    if (example.data_sources && example.data_sources.data) {
      for (var j = 0; j < example.data_sources.data.length; j++) {
        var src = example.data_sources.data[j]
        var existingSrcName = ""
        for (var s = 0; s < app.data_sources.length; s++) {
          if (app.data_sources[s].id === src.id) {
            existingSrcName = app.data_sources[s].name || app.data_sources[s].id
            break
          }
        }
        if (existingSrcName !== "") {
          app.signal_error('LibraryPage', "importExample", 'Source already exists as: ' + existingSrcName)
          return
        }
        newSources.push(src)
      }
    }

    if (example.flows && example.flows.data) {
      for (var k = 0; k < example.flows.data.length; k++) {
        var flw = example.flows.data[k]
        var existingFlwName = ""
        for (var f = 0; f < app.flows.length; f++) {
          if (app.flows[f].id === flw.id) {
            existingFlwName = app.flows[f].name || app.flows[f].id
            break
          }
        }
        if (existingFlwName !== "") {
          app.signal_error('LibraryPage', "importExample", 'Flow ID already exists as: ' + existingFlwName)
          return
        }
        newFlows.push(flw)
      }
    }

    if (example.value_maps && example.value_maps.data) {
      var maps = example.value_maps.data
      for (var mapKey in maps) {
        if (app.value_maps[mapKey] !== undefined) {
          app.signal_error('LibraryPage', "importExample", 'Value Map already exists: ' + mapKey)
          return
        }
        newValueMaps[mapKey] = maps[mapKey]
      }
    }

    console.debug("import data_sources:", newSources.length, "flows:", newFlows.length, "actions:", newActions.length, "maps:", Object.keys(newValueMaps).length)

    if (newActions.length > 0) {
      var actList = app.actions
      for (var na = 0; na < newActions.length; na++) { actList.push(newActions[na]) }
      app.actions = []
      app.actions = actList
      python.save_actions()
    }

    if (newSources.length > 0) {
      var srcList = app.data_sources
      for (var ns = 0; ns < newSources.length; ns++) { srcList.push(newSources[ns]) }
      app.data_sources = []
      app.data_sources = srcList
      python.save_data_sources()
    }

    if (newFlows.length > 0) {
      var flwList = app.flows
      for (var nf = 0; nf < newFlows.length; nf++) { flwList.push(newFlows[nf]) }
      app.flows = []
      app.flows = flwList
      python.save_flows()
    }

    if (Object.keys(newValueMaps).length > 0) {
      var currentMaps = app.value_maps
      for (var key in newValueMaps) {
        currentMaps[key] = newValueMaps[key]
      }
      app.value_maps = {}
      app.value_maps = currentMaps
      python.save_value_maps()
    }

    if (newActions.length > 0 || newSources.length > 0 || newFlows.length > 0 || Object.keys(newValueMaps).length > 0) {
      python.load_data()
    }
  }

  Component.onCompleted: fetchLibrary()
}
