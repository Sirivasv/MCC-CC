import flask
from flask import Flask, request, make_response
from flask_cors import CORS
from music21 import musicxml, metadata
from wrappedcoconet import WrappedCoconet
import music21

app = Flask(__name__)
CORS(app)

timesignature = music21.meter.TimeSignature('4/4')

coconet_checkpoint_path = "../trained_coconet_checkpoint/coconet_checkpoint/" \
                          + "coconet-64layers-128filters/"

wcoco = WrappedCoconet(
  gen_batch_size=1, strategy="harmonize_midi_melody",
  temperature=0.99, piece_length=8,
  generation_output_dir="./generated_samples/",
  prime_midi_melody_fpath="./tempMIDIFROMFLSK.mid",
  checkpoint=coconet_checkpoint_path, midi_io=False,
  tfsample=False)

@app.route('/', methods=['GET','POST'])
def upload_file():
    sheet = music21.converter.parseData(request.form["fileContent"], format="musicxml")
    sheet.write('midi', "tempMIDIFROMFLSK.mid")

    final_harmonization_path = wcoco.run_sampling()

    cmid = music21.converter.parse(final_harmonization_path, format='midi')
    GEX = music21.musicxml.m21ToXml.GeneralObjectExporter(cmid)
    out = GEX.parse()  # out is bytes
    outStr = out.decode('utf-8')

    return outStr

app.run(host='0.0.0.0', port=5000, threaded=True)