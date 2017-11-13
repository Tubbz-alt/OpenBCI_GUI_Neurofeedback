
////////////////////////////////////////////////////
//
//    W_neurofeedback.pde
//
//    A tone neurofeedback for alpha band (7.5-12.5Hz) for all channels. The tone is hardcoded. The feedback is
//    both with amplitude of the tone and slight changes of frequency. The tone is different for each feedback channel. 
//    This is a pretty basic, but working feedback proof of concept.
//    You can also do feedback on hemicoherence and enable alpha+/beta- feedback
//    instead of alpha+ only
//
//    Created by: Juraj Bednár
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
  
  int hemicoherence_chan1 = 0;
  int hemicoherence_chan2 = 1;

  float noise_cutoff_level = 3;
  boolean hemicoherence_enabled = false;
  boolean alphaOnly = true;
  float[] hemicoherenceMemory;
  final int hemicoherenceMemoryLength = 10;
  int hemicoherenceMemoryPointer = 0;


  W_neurofeedback(PApplet _parent) {
    super(_parent); //calls the parent CONSTRUCTOR method of Widget (DON'T REMOVE)
  
    List <String> channelList = new ArrayList<String>();
    for (int i = 0; i < nchan; i++) {
      channelList.add(Integer.toString(i + 1));
    }
  
    addDropdown("FeedbackType", "Type", Arrays.asList("alph+", "alph+ bet-"), 0);
    addDropdown("NoiseCutoffLevel", "Cutoff", Arrays.asList("2 uV", "3 uV", "4 uV", "5 uV",
        "6 uV", "7 uV", "8 uV", "9 uV", "10 uV"), 1);

    addDropdown("HemicoherenceEnable", "HC Feedback", Arrays.asList("Off", "On"), 0);
    addDropdown("HemicoherenceChan1", "Chan A", channelList, hemicoherence_chan1);
    addDropdown("HemicoherenceChan2", "Chan B", channelList, hemicoherence_chan2);
  
    hemicoherenceMemory = new float[hemicoherenceMemoryLength];
    for (int i=0;i<hemicoherenceMemoryLength;i++) {
      hemicoherenceMemory[i] = 0f;
    }
    
    minim = new Minim(this);
    out = minim.getLineOut();
    float panFactor = 0f;                 // 1 means total left/right pan, 0 means MONO (all tones in both
                                          // channels, 0.8f means mixing 80/20, good for headphones

    // create a sine wave Oscil, set to 440 Hz, at 0.5 amplitude
    waves = new Oscil[(nchan + 1) * numHarmonic]; // we have one tone for hemicoherence, this nchan+1
    for (int i=0 ; i<nchan + 1; i++) 
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
    float coherence1_alpha_amplitude = 0;
    float coherence2_alpha_amplitude = 0;
    float coherence1_beta_amplitude = 0;
    float coherence2_beta_amplitude = 0;

    for (int Ichan=0;Ichan < nchan; Ichan++) {

     if (isChannelActive(Ichan)) {
      //loop over each new sample

      float alpha_amplitude = 0;
      float alpha_max_amplitude = 0;
      int alpha_samples = 0;

      float beta_amplitude = 0;
      float beta_max_amplitude = 0;
      int beta_samples = 0;


      for (int Ibin=0; Ibin < fftData[Ichan].specSize(); Ibin++){
        FFT_freq_Hz = fftData[Ichan].indexToFreq(Ibin);
        FFT_value_uV = fftData[Ichan].getBand(Ibin);
        
        if ((FFT_freq_Hz >= 7.5) && (FFT_freq_Hz <= 12.5)) { // FFT bins in alpha range
          if (FFT_value_uV > alpha_max_amplitude) alpha_max_amplitude = FFT_value_uV;
          alpha_amplitude += FFT_value_uV;
          alpha_samples++;
        }
        else if (FFT_freq_Hz > 12.5 && FFT_freq_Hz <= 30) {  // FFT bins in beta range
          if (FFT_value_uV > beta_max_amplitude) beta_max_amplitude = FFT_value_uV;
          beta_amplitude += FFT_value_uV;
          beta_samples++;
        }
     }

     if (hemicoherence_enabled) {
      if (Ichan == hemicoherence_chan1) {
        coherence1_alpha_amplitude = alpha_amplitude;
        coherence1_beta_amplitude = beta_amplitude;
      } else if (Ichan == hemicoherence_chan2) {
        coherence1_alpha_amplitude = alpha_amplitude;
        coherence1_beta_amplitude = beta_amplitude;
      }
     }

     alpha_amplitude = alpha_amplitude / alpha_samples;
     beta_amplitude = beta_amplitude / beta_samples;

     if (hemicoherence_enabled) {
      if (Ichan == hemicoherence_chan1) {
        coherence1_alpha_amplitude = alpha_amplitude;
        coherence1_beta_amplitude = beta_amplitude;
      } else if (Ichan == hemicoherence_chan2) {
        coherence1_alpha_amplitude = alpha_amplitude;
        coherence1_beta_amplitude = beta_amplitude;
      }
     }

     System.out.println((Ichan+1) + ": alpha: " + (alpha_amplitude/alpha_samples) + 
       "(max: " + alpha_max_amplitude +") over " + alpha_samples +" samples");

     if (alpha_amplitude < noise_cutoff_level) { // to avoid noise when a person is moving
       if (alphaOnly) {
        setTone(Ichan, map(alpha_amplitude, 0, noise_cutoff_level, 0, 1)); // or some other range?
       } else { // alpha - beta
        setTone(Ichan, map(constrain(alpha_amplitude - beta_amplitude, 0, noise_cutoff_level),
          0, noise_cutoff_level, 0, 1)); // or some other range?
       }
     } else setTone(Ichan,0);
    } else setTone(Ichan,0);

   }

    // hemicoherence calculation
    // TODO: this is coherence of averages, not of samples
    if (hemicoherence_enabled) {
      float hemiIncoherenceAmplitude = abs(coherence1_alpha_amplitude - coherence2_alpha_amplitude);
      if (!alphaOnly) {
        hemiIncoherenceAmplitude += abs(coherence1_beta_amplitude - coherence2_beta_amplitude);
        hemiIncoherenceAmplitude = hemiIncoherenceAmplitude/2;
      }

      System.out.println("Hemicoherence factor " + pow(0.95, hemiIncoherenceAmplitude));
      addHemiCoherence(pow(0.95, hemiIncoherenceAmplitude));
    } else setTone(nchan, 0);
    
  }

  void addHemiCoherence(float x) {
    hemicoherenceMemory[hemicoherenceMemoryPointer] = x;
    hemicoherenceMemoryPointer++;
    if (hemicoherenceMemoryPointer>=hemicoherenceMemoryLength)
      hemicoherenceMemoryPointer = 0;
    
    float averageAmplitude = 0f;
    float maxAmplitude = 0f;
    for (int i=0;i<hemicoherenceMemoryLength;i++) {
      averageAmplitude+= hemicoherenceMemory[i]; 
      if (hemicoherenceMemory[i]>maxAmplitude)
        maxAmplitude = hemicoherenceMemory[i];
    }
    averageAmplitude = averageAmplitude/hemicoherenceMemoryLength;
    
    //setTone(nchan, maxAmplitude);
    setTone(nchan, averageAmplitude);
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

void NoiseCutoffLevel (int n) {
  w_neurofeedback.noise_cutoff_level = n + 2;
  closeAllDropdowns();
}

void FeedbackType(int n) {
  if (n==0) w_neurofeedback.alphaOnly = true;
  else w_neurofeedback.alphaOnly = false;
  closeAllDropdowns();
}

void HemicoherenceEnable(int n) {
  if (n==0) w_neurofeedback.hemicoherence_enabled = false;
  else w_neurofeedback.hemicoherence_enabled = true;
  closeAllDropdowns();
}

void HemicoherenceChan1(int n) {
  w_neurofeedback.hemicoherence_chan1 = n;
  closeAllDropdowns();
}

void HemicoherenceChan2(int n) {
  w_neurofeedback.hemicoherence_chan2 = n;
  closeAllDropdowns();
}