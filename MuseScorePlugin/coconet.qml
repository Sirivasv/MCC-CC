import QtQuick 2.9
import QtQuick.Controls 2.2
import MuseScore 3.0

MuseScore {
        
    id: mainMuseScoreObj
    menuPath: "Plugins.COCONET"
    description: "Harmonization AI tool."
    pluginType: "dock"
    dockArea:   "left"
    version: "1.0"
    
    onRun: {
        console.log("hello world")
    }
    
    Rectangle {
        id: wrapperPanel
        
        Text {
            id: title
            text: "Coconet"
            font.family: "Helvetica"
            font.pointSize: 24
            color: "blue"
            anchors.top: wrapperPanel.top
            anchors.topMargin: 10
            font.underline: true
            }
        
        Label {
            id: serverInputLabel
            wrapMode: Text.WordWrap
            text: 'Server address'
            font.pointSize:12
            anchors.left: wrapperPanel.left
            anchors.top: title.top
            anchors.topMargin: 70
        }
    
        TextField {
            id: serverAddressInput
            text: "http://localhost:5000/"
            anchors.left: wrapperPanel.left
            anchors.top: serverInputLabel.top
            anchors.topMargin: 25
            width: 200
            height: 35
        }

        Button {
            id : buttonHarmonize
            text: qsTr("Harmonize")
            background: Rectangle {
                color: buttonHarmonize.down ? "#00bfff" : "#1e90ff"
            }
            anchors.left: wrapperPanel.left
            anchors.top: serverAddressInput.top
            anchors.topMargin: 50
            anchors.bottomMargin: 10
            onClicked: {
                submitScore()
            }
        }

    }

    Dialog {
        id: status_dialog
        modal: true
        standardButtons: Dialog.Ok
        title: "Status"
        contentItem: Rectangle{
            implicitWidth: parent.width
            Text {
                text: ""
                verticalAlignment: Text.AlignVCenter
            }
    
        }
    }
    

    function submitScore(){
        console.log('Button Pressed' + serverAddressInput.text);
        status_dialog.Rectangle.text = "Submitted..."
        status_dialog.open();
        waitAMinuteWhoAreYou();
    }

    function waitAMinuteWhoAreYou() {
        for (var i = 0; i < 1000000000; i++){
        }
    }
}
