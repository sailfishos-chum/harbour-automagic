import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0

Page {
  id: main_page

  property string dynamicPage: app.dynamic_page

  onDynamicPageChanged: {
    var newTitle = dynamicPage === "logs" ? "Log" : "States"
    tab_model.setProperty(3, "title", newTitle)
  }

  TabView {
    id: tabs
    anchors.fill: parent
  
    header: TabBar {
      model: tab_model
    }

    model: [data_sources_tab, flows_tab, actions_tab, dynamic_tab]

    Component {
      id: data_sources_tab
      TabItem {
        SourcesPage {
          anchors.fill: parent
          id: data_sources_page
        }
      }
    }

    Component {
      id: flows_tab
      TabItem {
        FlowsPage {
          anchors.fill: parent
          id: flows_page
        }
      }
    }

    Component {
      id: actions_tab
      TabItem {
        ActionsPage {
          anchors.fill: parent
          id: actions_page
        }
      }
    }

    Component {
      id: dynamic_tab
      TabItem {
        Loader {
          anchors.fill: parent
          sourceComponent: main_page.dynamicPage === "logs" ? logs_page_comp : states_page_comp
        }
      }
    }
  }

  ListModel {
    id: tab_model

    ListElement {
      title: "Sources"
    }
    ListElement {
      title: "Flows"
    }
    ListElement {
      title: "Actions"
    }
    ListElement {
      title: "States"
    }
  }

  Component {
    id: states_page_comp
    StatesPage {
      anchors.fill: parent
    }
  }

  Component {
    id: logs_page_comp
    LogsPage {
      anchors.fill: parent
    }
  }

  Component.onCompleted: {
    if (app.settings && app.settings.startup_tab !== undefined) {
      tabs.currentIndex = parseInt(app.settings.startup_tab)
    } else {
      tabs.currentIndex = 1
    }
  }

  Component.onDestruction: {
  }
}
