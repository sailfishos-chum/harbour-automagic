import QtQuick 2.2
import Sailfish.Silica 1.0

StepBase {
  id: stepBase
  stepType: "get"
  
  property string sourceId: ""
  property string functionId: ""
  property var paramsArray: []
  property var mappingArray: []

  signal changeSourceRequested()

  Column {
    width: parent.width
    spacing: 0

    BackgroundItem {
      width: parent.width
      height: Theme.itemSizeSmall
      onClicked: stepBase.changeSourceRequested()
      
      Label {
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
        color: Theme.primaryColor
        
        text: {
          if (sourceId !== "") {
            var sources = app.data_sources
            if (sources) {
              if (Array.isArray(sources)) {
                for (var i = 0; i < sources.length; i++) {
                  if (sources[i].id === sourceId && sources[i].name) return sources[i].name
                }
              } else if (sources[sourceId] && sources[sourceId].name) {
                return sources[sourceId].name
              }
            }
            return "Unknown Source"
          } 

          if (functionId !== "") {
            return functionId + "()"
          }

          return "Select Source..."
        }
      }
    }

    BackgroundItem {
      width: parent.width
      height: Math.max(Theme.itemSizeSmall, paramsLabel.height + Theme.paddingMedium)
      visible: sourceId !== "" || functionId !== ""
      onClicked: stepBase.editParamsRequested("step_types", "get_" + functionId)

      Label {
        id: paramsLabel
        width: parent.width - (Theme.paddingLarge * 2)
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
        text: {
          if (!paramsArray || paramsArray.length === 0) {
            return "[no parameters]"
          }
          var lines = [];
          for (var i = 0; i < paramsArray.length; i++) {
            lines.push(paramsArray[i].key + ": " + paramsArray[i].value);
          }
          return lines.join("\n");
        }
      }

      Icon {
        id: forward_action_icon
        source: "../../icons/arrow_forward.svg"
        height: 40
        width: height
        anchors {
          verticalCenter: parent.verticalCenter
          right: parent.right
          rightMargin: Theme.paddingSmall
        }
      }
    }

    Column {
      width: parent.width
      visible: mappingArray && mappingArray.length > 0
      
      Separator { 
        width: parent.width; 
        color: Theme.secondaryHighlightColor; 
        horizontalAlignment: Qt.AlignHCenter 
      }

      Repeater {
        model: mappingArray
        delegate: Item {
          width: parent.width
          height: Theme.itemSizeExtraSmall
          
          Row {
            anchors.centerIn: parent
            spacing: Theme.paddingSmall
            
            Label {
              text: modelData.key
              font.pixelSize: Theme.fontSizeExtraSmall
              color: Theme.secondaryColor
            }
            
            Icon {
              source: "image://theme/icon-m-enter-next"
              scale: 0.5
              anchors.verticalCenter: parent.verticalCenter
            }
            
            Label {
              text: modelData.value
              font.pixelSize: Theme.fontSizeExtraSmall
              font.bold: true
              color: Theme.primaryColor
            }
          }
        }
      }
    }
  }
}
