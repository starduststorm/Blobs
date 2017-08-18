import processing.sound.*;

public class SpectrumAnalyzer extends IdlePattern
{
  FFT fft;
  AudioIn audioIn;
  
  final int kAudioBands = 64;
  
  float[] audioSpectrum = new float[kAudioBands];
  float[] normalizedSpectrum = new float[kAudioBands];
  
  final float kVolumeThreshold = 3.5; // volume at which to start fading waveform out
  float volumeRunningAverage = 0;
  final int kVolumeFrameCount = 300; // how many frames to run the running average over
  
  float volumeAlpha;
  
  public SpectrumAnalyzer(int displayWidth, int displayHeight, PApplet sketch)
  {
    super(displayWidth, displayHeight);
    fft = new FFT(sketch, kAudioBands);
    audioIn = new AudioIn(sketch, 0);
    audioIn.start();
    fft.input(audioIn);
  }
  
  void updateWaveform()
  {
    fft.analyze(audioSpectrum);
    
    float volumePeak = 0;
    for (int i = 0; i < kAudioBands; ++i) {
      // amplify and balance across the banner
      float moddedAudio = audioSpectrum[i] * blobsRegionHeight * 100 * (i/8.0+4);
      
      final float normCount = 5.0;
      normalizedSpectrum[i] = (normalizedSpectrum[i] * (normCount - 1) + moddedAudio) / normCount;

      if (audioSpectrum[i] > volumePeak) {
        volumePeak = normalizedSpectrum[i];
      }
    }
    
    volumeRunningAverage = (volumeRunningAverage * (kVolumeFrameCount - 1) + volumePeak) / kVolumeFrameCount;  
    
    volumeAlpha = 100;
    
    if (volumeRunningAverage < kVolumeThreshold) {
      // fade waveform out if quiet for too long
      volumeAlpha = 100 * max(0, 5 * volumeRunningAverage / kVolumeThreshold - 4);
    }
  }
  
  boolean wantsToRun()
  {
    this.updateWaveform();
    return this.volumeAlpha > 0;
  }
  
  void update()
  {
    this.updateWaveform();
    this.draw();
  }
  
  public void draw()
  {
    blendMode(BLEND);
    colorMode(HSB, 100);
    
    float prevAmp = -1;
    float waveformAlpha = 0.4 * volumeAlpha;
    
    for (int i = 0; i < kAudioBands; ++i) {
      float amp = normalizedSpectrum[i];
      if (amp > blobsRegionHeight / 2.0) {
        amp = log(amp - blobsRegionHeight / 2.) + blobsRegionHeight / 2.;
      }
      
      // Flip upside down
      amp = blobsRegionHeight - amp;
      
      if (prevAmp != -1) {
        final float stretch = 2.0;
        
        //float hue = (i + millis() / 100.0);
        float rangeMin = millis() / 1000.0;
        int rangeLen = 30;
        float hue = (i + millis() / 200.0 + rangeMin) % ((rangeMin + rangeLen) * 2);
        hue = (hue > (rangeMin + rangeLen) ? (rangeMin + rangeLen)*2 - hue : hue);
        //float hue = (amp * 6 + millis() / 100.0);
        stroke(hue % 100, 100, 100, waveformAlpha);

        line(displayWidth / 2.0 + stretch * i - stretch, prevAmp, displayWidth / 2.0 + stretch * i, amp);
        line(displayWidth / 2.0 - stretch * i + stretch, prevAmp, displayWidth / 2.0 - stretch* i, amp);
      }
      
      prevAmp = amp;
    }
  }
  
}