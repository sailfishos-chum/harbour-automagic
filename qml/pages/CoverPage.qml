import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
  id: cover

  Label {
    id: name_label
    anchors {
      top: parent.top
      horizontalCenter: parent.horizontalCenter
      topMargin: Theme.paddingLarge
    }
    opacity: 1
    text: "Automagic"
    font.pixelSize: Theme.fontSizeSmall
  }

  Icon {
    source: "../../icons/logo.png"
    color: Theme.highlightColor
    opacity: 0.1
    height: parent.width
    width: parent.width
    anchors {
      verticalCenter: parent.verticalCenter
      horizontalCenter: parent.horizontalCenter
    }
  }


  Component.onCompleted: {

  }

  Component.onDestruction: {

  }
}
