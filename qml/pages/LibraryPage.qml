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
      contentHeight: Theme.itemSizeLarge
      visible: modelData.name !== undefined

      Column {
        anchors {
          left: parent.left
          right: parent.right
          leftMargin: Theme.horizontalPageMargin
          verticalCenter: parent.verticalCenter
        }

        Label {
          text: modelData.name
          color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
        }

        Label {
          text: modelData.description || "Automation template"
          font.pixelSize: Theme.fontSizeSmall
          color: Theme.secondaryColor
          width: parent.width
          truncationMode: TruncationMode.Fade
        }
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
            console.log("Error parsing library JSON")
          }
          page.loading = false
        }
      }
    }
    xhr.open("GET", "https://qml.app/automagic/examples.php")
    xhr.send()
  }

  function importExample(example) {
    var changed = false

    if (example.sources && example.sources.data) {
      example.sources.data.forEach(function(s) {
        if (!app.config.sources.some(function(x) { return x.id === s.id })) {
          app.config.sources.push(s)
          changed = true
        }
      })
    }

    if (example.actions && example.actions.data) {
      example.actions.data.forEach(function(a) {
        if (!app.config.actions.some(function(x) { return x.id === a.id })) {
          app.config.actions.push(a)
          changed = true
        }
      })
    }

    if (example.flows && example.flows.data) {
      example.flows.data.forEach(function(f) {
        if (!app.config.flows.some(function(x) { return x.id === f.id })) {
          app.config.flows.push(f)
          changed = true
        }
      })
    }

    if (changed) {
      app.saveConfig()
    }
  }

  Component.onCompleted: fetchLibrary()
}
