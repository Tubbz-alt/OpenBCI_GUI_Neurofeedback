### Neurofeedback widget for the OpenBCI_GUI

This version of standard [OpenBCI_GUI](https://github.com/OpenBCI/OpenBCI_GUI) adds a tone neurofeedback for alpha band (7.5-12.5Hz) for all channels. The tone is hardcoded. The feedback is both with amplitude of the tone and slight changes of frequency. The tone is different for each feedback channel. This is a pretty basic, but working feedback proof of concept.

Caveats: 

- I recommend turning unused channels off before starting (use keys 1-8)
- Tune down the volume when starting :)

The code tries to detect artifacts (like jaw movement) by ignoring "superloud tones" over a certain maximal amplitude - when the tone goes over this threshold, the tone is actually set to total silence.

There is also an option to have hemicoherence tone. You would set up A
and B channels in the GUI with channels corresponding to the same
position on both hemispheres. The difference between these two signals
is the opposite to coherence, the lower the number, the louder the tone.

Installation
============

You can use this software instead of official and the neurofeedback should just work when you select
the neurofeedback widget in the GUI :).

For installation instructions see [the original documentation on
running OpenBCI_GUI from
Processing](http://docs.openbci.com/OpenBCI%20Software/01-OpenBCI_GUI#the-openbci-gui-running-the-openbci-gui-from-the-processing-ide).
Please note that in addition to running it from the IDE, you need
to copy libraries and the sketch to the right directory and download
and setup Ganglion Hub for Ganglion boards, the documentation is
pretty specific on what to do, if you follow it, it will work!

If you do not see any Ganglion Bluetooth devices and you have Bluetooth on,
it probably means that Ganlgion Hub is not set up correctly - you need
to put it into the correct directory and not run it as a standalone app!

Released under original MIT license, (c) 2017 Juraj Bednár

Original README follows.
=======
Project Management Plan:
[![Stories in Ready](https://badge.waffle.io/OpenBCI/OpenBCI_GUI_v2.0.svg?label=ready&title=Ready)](http://waffle.io/OpenBCI/OpenBCI_GUI_v2.0)

# OpenBCI_GUI_v2.0
Based on OpenBCI_Processing, OpenBCI_GUI_v2.0 extends the GUI to include additional features, and interfaces with the OpenBCI [Cyton](http://shop.openbci.com/collections/frontpage/products/openbci-32-bit-board-kit?variant=784651699) and [Ganglion](http://shop.openbci.com/collections/frontpage/products/pre-order-ganglion-board?variant=13461804483) hardware systems. Tutorials, and getting started guides can be found on the [OpenBCI Learning Pages](http://docs.openbci.com/Getting%20Started/00-Welcome). For a guide on how to run this code in the Processing IDE, go [here](http://docs.openbci.com/OpenBCI%20Software/01-OpenBCI_GUI)
