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
		
		dialogProgressContentText.text = dialogString;
		waiting_dialog.open();
		var originScore = curScore;
		var cursor_moving_origin = originScore.newCursor();
    cursor_moving_origin.rewind(1);
		var cursor_limit_origin = originScore.newCursor();
    cursor_limit_origin.rewind(2);

		var tick_start_origin = cursor_moving_origin.tick;
		var tick_end_origin = cursor_limit_origin.tick;

		
		var nmeasures = 0;
		var last_measure_jump = true;
		for (;(cursor_moving_origin.tick < tick_end_origin) && last_measure_jump;
				last_measure_jump = cursor_moving_origin.nextMeasure()) {
			nmeasures++;
		}
		console.log("N_measures = " + nmeasures);
    cursor_moving_origin.rewind(1);
		
		var score_to_send = newScore("score_to_send.mscz", "Piano", nmeasures);
		score_to_send.startCmd();
    score_to_send.addText("title", originScore.title);
    score_to_send.addText("composer", originScore.composer);
	
		var cursor_moving_destiny = score_to_send.newCursor();
		cursor_moving_destiny.rewind(0);
		var ts = newElement(Element.TIMESIG);
		ts.timesig = fraction(4,4);
		cursor_moving_destiny.add(ts);

		var tempoElement = newElement(Element.TEMPO_TEXT);
		tempoElement.text = '<sym>metNoteQuarterUp</sym> = ' + 120;
		tempoElement.visible = true;
		cursor_moving_destiny.add(tempoElement);
		//changing of tempo can only happen after being added to the segment
		tempoElement.tempo = 2;
		

		var last_cursor_jump = true;
		var previous_pitch = 0;
		var previous_tick = 0;
		var current_sixths = 0;
		var limit_sixths = nmeasures * 16;
		var flag_start = 0;
		for (;(cursor_moving_origin.tick < tick_end_origin) && last_cursor_jump;last_cursor_jump = cursor_moving_origin.next()) {
			console.log(cursor_moving_origin.tick);
			var e = cursor_moving_origin.element;
			var el_note = 0;
			for(var note_i = 0; note_i < e.notes.length; ++note_i){
				el_note = e.notes[note_i];
				console.log("type:", el_note.name, "at  pirtch:", el_note.pitch, "type", el_note.type);
				var d = el_note.duration;
        console.log("   duration " + d.numerator + "/" + d.denominator);
			}
			if (flag_start != 0) {
				var numerator_cur = (cursor_moving_origin.tick - previous_tick) / 120;
				current_sixths += numerator_cur;
				cursor_moving_destiny.setDuration(numerator_cur, 16);
				cursor_moving_destiny.addNote(previous_pitch);
			}
			flag_start = 1;
			previous_pitch = el_note.pitch;
			previous_tick = cursor_moving_origin.tick;
		}
		cursor_moving_destiny.setDuration((limit_sixths - current_sixths), 16);
		cursor_moving_destiny.addNote(previous_pitch);
	
		score_to_send.endCmd();
		var res = writeScore(score_to_send, myFile.source, "musicxml");
		console.log(myFile.source);
		console.log(res);
		// closeScore(score_to_send);


		var message_to_send = {
			fileSource: myFile.source,
			serverAddress: serverAddressInput.text,
			tick_start_origin: tick_start_origin,
			tick_end_origin: tick_end_origin,
			fileContent: myFile.read(),
			sheet_title: originScore.title,
			sheet_composer: originScore.composer
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
				readScore(myFileMXML.source)
			}
		)

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
