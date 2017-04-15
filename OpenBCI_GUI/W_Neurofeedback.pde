
////////////////////////////////////////////////////
//
//    W_neurofeedback.pde
//
//    A tone neurofeedback for alpha band (7.5-12.5Hz) for all channels. The tone is hardcoded. The feedback is
//    both with amplitude of the tone and slight changes of frequency. The tone is different for each feedback channel. 
//    This is a pretty basic, but working feedback proof of concept.
//
//    Created by: Juraj Bednár, April 2017
//
///////////////////////////////////////////////////,

import ddf.minim.Minim;
import ddf.minim.AudioOutput;
import ddf.minim.ugens.*;

class W_neurofeedback extends Widget {

  Minim       minim;
  AudioOutput out;
  Oscil[]       waves;
  int numHarmonic = 2; // number of harmonic frequencies for each wave


  W_neurofeedback(PApplet _parent) {
    super(_parent); //calls the parent CONSTRUCTOR method of Widget (DON'T REMOVE)
  
    minim = new Minim(this);
    out = minim.getLineOut();
    float panFactor = 0f;                 // 1 means total left/right pan, 0 means MONO (all tones in both
                                          // channels, 0.8f means mixing 80/20, good for headphones

    // create a sine wave Oscil, set to 440 Hz, at 0.5 amplitude
    waves = new Oscil[nchan * numHarmonic];
    for (int i=0 ; i<nchan; i++) 
      for (int j=0 ; j<numHarmonic ; j++) {
      waves[(i*numHarmonic)+j] = new Oscil( baseFrequency(i,0f)*(j+1), 0.0f, Waves.SINE );
      if (i%2 == 0) {
        Pan left = new Pan((-1f) * panFactor);
        waves[(i*numHarmonic)+j].patch( left );
        left.patch( out );
      }
      else {
        Pan right = new Pan(1f * panFactor);
        waves[(i*numHarmonic)+j].patch( right );
        right.patch(out);
      }
    }
  }

  private float baseFrequency(int channel, float amplitude) {
    return (400 + (channel*(400/nchan)) /* + (100*amplitude)*/);
  }

  private void setTone(int channel, float amplitude) {
    for (int j=0 ; j<numHarmonic ; j++) {
      waves[(channel*numHarmonic)+j].setAmplitude(amplitude);
      waves[(channel*numHarmonic)+j].setFrequency(baseFrequency(channel, amplitude)*(j+1)); // 400 - 800Hz is the best frequency
    }
  }

  void update(){
    super.update(); //calls the parent update() method of Widget (DON'T REMOVE)
    process(yLittleBuff_uV, dataBuffY_uV, dataBuffY_filtY_uV, fftBuff);
  }

public void process(float[][] data_newest_uV, //holds raw EEG data that is new since the last call
        float[][] data_long_uV, //holds a longer piece of buffered EEG data, of same length as will be plotted on the screen
        float[][] data_forDisplay_uV, //this data has been filtered and is ready for plotting on the screen
        FFT[] fftData) {              //holds the FFT (frequency spectrum) of the latest data

    float FFT_freq_Hz, FFT_value_uV;
    for (int Ichan=0;Ichan < nchan; Ichan++) {
      //loop over each new sample
      
      float amplitude = 0;
      float max_amplitude = 0;
      int samples = 0;
      
      for (int Ibin=0; Ibin < fftData[Ichan].specSize(); Ibin++){
        FFT_freq_Hz = fftData[Ichan].indexToFreq(Ibin);
        FFT_value_uV = fftData[Ichan].getBand(Ibin);
        
        if ((FFT_freq_Hz >= 7.5) && (FFT_freq_Hz <= 12.5)) { // we're in alpha band
            if (FFT_value_uV > max_amplitude) max_amplitude = FFT_value_uV;
            amplitude = amplitude + FFT_value_uV;
            samples++;
        }
     }

     if (isChannelActive(Ichan)) {
        System.out.println((Ichan+1) + ": " + (amplitude/samples) + "(max: " + max_amplitude +") over " + samples +" samples");
        if (max_amplitude < 15) setTone(Ichan, map((max_amplitude<10) ? max_amplitude : 10, 0, 10, 0, 1));
          else setTone(Ichan,0);
    
     } else setTone(Ichan,0);

    }  
  }


  void draw(){
    super.draw(); //calls the parent draw() method of Widget (DON'T REMOVE)

    //put your code here... //remember to refer to x,y,w,h which are the positioning variables of the Widget class
    pushStyle();

    //widgetTemplateButton.draw();

    popStyle();

  }

  void screenResized(){
    super.screenResized(); //calls the parent screenResized() method of Widget (DON'T REMOVE)

    //put your code here...
    /*
    widgetTemplateButton.setPos(x + w/2 - widgetTemplateButton.but_dx/2, y + h/2 - widgetTemplateButton.but_dy/2);
    */

  }

  void mousePressed(){
    super.mousePressed(); //calls the parent mousePressed() method of Widget (DON'T REMOVE)

    /*//put your code here...
    if(widgetTemplateButton.isMouseHere()){
      widgetTemplateButton.setIsActive(true);
    }*/

  }

  void mouseReleased(){
    super.mouseReleased(); //calls the parent mouseReleased() method of Widget (DON'T REMOVE)

    //put your code here...
    /*
    if(widgetTemplateButton.isActive && widgetTemplateButton.isMouseHere()){
      widgetTemplateButton.goToURL();
    }
    widgetTemplateButton.setIsActive(false);
    */
  }


};