import flask
from flask import Flask, request, make_response
from flask_cors import CORS
from music21 import musicxml, metadata
import music21

app = Flask(__name__)
CORS(app)

timesignature = music21.meter.TimeSignature('4/4')

@app.route('/', methods=['GET','POST'])
def upload_file():

    for i in range(20000000):
        j = i **2

    print(request.form["fileSource"])

    with open("tempMXML.musicxml","w") as fo:
        fo.write(request.form["fileContent"])

    sheet = music21.converter.parseData(request.form["fileContent"], format="musicxml")
    #insert_musicxml_metadata(sheet)
    sheet.write('midi', "tempMIDIFROMFLSK.mid")

    cmid = music21.converter.parse('tempMIDIFROMFLSK.mid', format='midi')
    GEX = music21.musicxml.m21ToXml.GeneralObjectExporter(cmid)
    out = GEX.parse()  # out is bytes
    outStr = out.decode('utf-8')

    return outStr
# def upload_file():
#    message_in_request = request
#        f.save('/var/www/uploads/uploaded_file.txt')

def sheet_to_midi_response(sheet):
    """
    Convert the provided sheet to midi and send it as a file
    """
    # midiFile = sheet.write('midi', "tempMIDIFROMFLSK.mid")
    # with open("tempMIDIFROMFLSK.mid","w") as fo:
    #     fo.write(midiFile)
    return flask.send_file(midiFile, mimetype="audio/midi",
                           cache_timeout=-1  # disable cache
                           )

def insert_musicxml_metadata(sheet: music21.stream.Stream):
    """
    Insert various metadata into the provided XML document
    The timesignature in particular is required for proper MIDI conversion
    """
    global timesignature

    from music21.clef import TrebleClef, BassClef, Treble8vbClef
    for part, name, clef in zip(
            sheet.parts,
            ['soprano', 'alto', 'tenor', 'bass'],
            [TrebleClef(), TrebleClef(), Treble8vbClef(), BassClef()]
    ):
        # empty_part = part.template()
        part.insert(0, timesignature)
        part.insert(0, clef)
        part.id = name
        part.partName = name

    md = metadata.Metadata()
    sheet.insert(0, md)

    # required for proper musicXML formatting
    sheet.metadata.title = 'DeepBach'
    sheet.metadata.composer = 'DeepBach'

app.run(host='0.0.0.0', port=5000, threaded=True)