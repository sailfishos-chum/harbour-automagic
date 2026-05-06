import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
  property var importData: ({})
  property var conflictList: []

  SilicaFlickable {
    anchors.fill: parent
    contentHeight: col.height

    Column {
      id: col
      width: parent.width

      DialogHeader {
        title: "Conflicts Found"
        acceptText: "Overwrite"
      }

      Label {
        width: parent.width - 2 * Theme.horizontalPageMargin
        x: Theme.horizontalPageMargin
        wrapMode: Text.WordWrap
        text: "The following items already exist and will be overwritten:"
        color: Theme.secondaryColor
        font.pixelSize: Theme.fontSizeSmall
      }

      Item { width: parent.width; height: Theme.paddingLarge }

      Repeater {
        model: conflictList
        Label {
          width: parent.width - 2 * Theme.horizontalPageMargin
          x: Theme.horizontalPageMargin
          text: "• " + modelData
          color: Theme.primaryColor
          font.pixelSize: Theme.fontSizeSmall
          wrapMode: Text.WordWrap
        }
      }

      Item { width: 1; height: Theme.paddingLarge }
    }
  }
}
