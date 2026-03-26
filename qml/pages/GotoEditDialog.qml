import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
  id: dialog

  property string draftGotoTarget: ""
  property string draftGotoAltTarget: ""
  property var availableSteps: []

  Column {
    width: parent.width
    spacing: Theme.paddingLarge

    DialogHeader {
      title: "Select Targets"
      acceptText: "Save"
    }

    ComboBox {
      id: stepSelector
      width: parent.width
      label: "Primary Jump"
      visible: availableSteps && availableSteps.length > 0

      currentIndex: {
        if (!availableSteps) return -1;
        for (var i = 0; i < availableSteps.length; i++) {
          if (availableSteps[i].id === dialog.draftGotoTarget) return i;
        }
        return 0;
      }

      menu: ContextMenu {
        Repeater {
          model: availableSteps
          MenuItem {
            text: modelData.label 
            onClicked: dialog.draftGotoTarget = modelData.id 
          }
        }
      }
    }

    ComboBox {
      id: altStepSelector
      width: parent.width
      label: "Alternative Jump"
      visible: availableSteps && availableSteps.length > 0

      currentIndex: {
        if (!availableSteps) return -1;
        for (var i = 0; i < availableSteps.length; i++) {
          if (availableSteps[i].id === dialog.draftGotoAltTarget) return i;
        }
        return 0;
      }

      menu: ContextMenu {
        Repeater {
          model: availableSteps
          MenuItem {
            text: modelData.label 
            onClicked: dialog.draftGotoAltTarget = modelData.id 
          }
        }
      }
    }

    Label {
      visible: !availableSteps || availableSteps.length === 0
      text: "No other steps available."
      color: Theme.secondaryColor
      x: Theme.horizontalPageMargin
    }
  }
}
