from wrappedcoconet import WrappedCoconet

coconet_checkpoint_path = "../trained_coconet_checkpoint/coconet_checkpoint/" \
                          + "coconet-64layers-128filters/"

wcoco = WrappedCoconet(
  gen_batch_size=1, strategy="harmonize_midi_melody",
  temperature=0.99, piece_length=8,
  generation_output_dir="./generated_samples/",
  prime_midi_melody_fpath="./probandoinfill.mid",
  checkpoint=coconet_checkpoint_path, midi_io=False,
  tfsample=False)

wcoco.run_sampling()