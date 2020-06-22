import QtQuick 2.9
import QtQuick.Controls 2.2
import MuseScore 3.0
import FileIO 3.0

MuseScore {
	menuPath: "Plugins.COCONET"
	description: "Harmonization AI tool."
	pluginType: "dock"
	dockArea:   "left"
	version: "1.0"

	FileIO {
        id: myFile
        source: "/home/sirivasv/Documents/MCC/MCC-CC/MuseScorePlugin/" + curScore.title + "_harmonized_by_coconet_SENT.musicxml"
        onError: console.log(msg)
    }

	FileIO {
        id: myFileMXML
        source: "/home/sirivasv/Documents/MCC/MCC-CC/MuseScorePlugin/" + curScore.title + "_harmonized_by_coconet_RESPONSE.musicxml"
        onError: console.log(msg)
    }


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

		WorkerScript {
			id: myWorker
			source: "coconet-dialog.js"
			onMessage: {
				console.log("DONE!");
				waiting_dialog.close();
				dialogStatusContentText.text = "Finished Harmonization!";
				status_dialog.open();
			}
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


      

		Dialog {
			id: waiting_dialog
			modal: true
			visible: false
			title: "Status"
			implicitWidth: 250
			implicitHeight: 500
			closePolicy: Popup.NoAutoClose
					
			contentItem: Rectangle{
				id: dialogProgressContent
				width: parent.width
				height: parent.height

				Text {
					id: dialogProgressContentText
					text: ""
					verticalAlignment: Text.AlignVCenter
				}

				ProgressBar {
					indeterminate: true
					width: parent.width
					anchors.top: dialogProgressContentText.top
					anchors.topMargin: 200
				}

			}
		}

		Dialog {
			id: status_dialog
			modal: true
			visible: false
			title: "Status"
			implicitWidth: 250
			implicitHeight: 500
			standardButtons: Dialog.Ok

			contentItem: Rectangle{
				id: dialogStatusContent
				width: parent.width
				height: parent.height

				Text {
					id: dialogStatusContentText
					text: ""
					verticalAlignment: Text.AlignVCenter
				}

			}
		}

		

	}


	function submitScore(){
		console.log('Button Pressed' + serverAddressInput.text);
		var dialogString = "Submitted!\nPlease Wait\nThis could take several minutes.\n";
		var res = writeScore(curScore, myFile.source, "musicxml");
		console.log(myFile.source);
		console.log(res);
		dialogProgressContentText.text = dialogString;
		waiting_dialog.open();

		var cursor_moving = curScore.newCursor();
        cursor_moving.rewind(1);
		var cursor_limit = curScore.newCursor();
        cursor_limit.rewind(2);

		var tick_start = cursor_moving.tick;
		var tick_end = cursor_limit.tick;

		var message_to_send = {
			fileSource: myFile.source,
			serverAddress: serverAddressInput.text,
			tick_start: tick_start,
			tick_end: tick_end,
			fileContent: myFile.read()
		};

		var request = getRequestObj("POST", message_to_send['serverAddress']);
		call(
			request,
			message_to_send,
			function(response) {
				console.log("DONE!");
				waiting_dialog.close();
				dialogStatusContentText.text = "Finished Harmonization!";
				status_dialog.open();
				myFileMXML.write(response);
			}
		)

		// myWorker.sendMessage(message_to_send);

	}


	function getRequestObj(method, endpoint) {
		console.debug('calling endpoint ' + endpoint);
		var request = new XMLHttpRequest();
		request.open(method, endpoint, true);
		return request;
	}

	function call(request, params, cb) {
		request.onreadystatechange = function() {
			if (request.readyState == XMLHttpRequest.DONE) {
				cb(request.responseText);
			}
		}

		if (params) {
			request.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
			var pairs = [];
			for (var prop in params) {
			if (params.hasOwnProperty(prop)) {
				var k = encodeURIComponent(prop),
					v = encodeURIComponent(params[prop]);
				pairs.push( k + "=" + v);
			}
			}

			const content = pairs.join('&')
			request.send(content)
		} else {
			request.send()
		}
		return true
	}
}
