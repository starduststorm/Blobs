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
  
  public SpectrumAnalyzer(int displayWidth, int displayHeight, PApplet sketch)
  {
    super(displayWidth, displayHeight);
    fft = new FFT(sketch, kAudioBands);
    audioIn = new AudioIn(sketch, 0);
    audioIn.start();
    fft.input(audioIn);
  }
  
  public void idleUpdate()
  {
    fft.analyze(audioSpectrum);
    
    float volumePeak = 0;
    for (int i = 0; i < kAudioBands; ++i) {
      // amplify and balance across the banner
      float moddedAudio = audioSpectrum[i] * blobsRegionHeight * 200 * (i / 8.0 + 4);
      
      final float normCount = 5.0;
      normalizedSpectrum[i] = (normalizedSpectrum[i] * (normCount - 1) + moddedAudio) / normCount;

      if (audioSpectrum[i] > volumePeak) {
        volumePeak = normalizedSpectrum[i];
      }
    }
    
    volumeRunningAverage = (volumeRunningAverage * (kVolumeFrameCount - 1) + volumePeak) / kVolumeFrameCount;  
  }
  
  public boolean wantsToRun()
  {
    this.idleUpdate();
    return volumeRunningAverage > 1.3 * kVolumeThreshold;
  }
  
  public boolean wantsToIdleStop()
  {
    return volumeRunningAverage < 2 * kVolumeThreshold;
  }
  
  public void update()
  {
    if (volumeRunningAverage < kVolumeThreshold) {
      if (this.isRunning()) {
        this.lazyStop();
      }
    }
    this.draw();
  }
  
  void draw()
  {
    blendMode(BLEND);
    colorMode(HSB, 100);
    
    float startStopAlpha = 1.0;
    float volumeAlpha = 1;
    
    if (volumeRunningAverage < kVolumeThreshold) {
      // fade waveform out if quiet for too long
      volumeAlpha = max(0, min(1, 5 * volumeRunningAverage / kVolumeThreshold - 4));
    }
    
    if (this.isStopping()) {
      startStopAlpha = 1 - (millis() - stopMillis) / 2000;
      if (startStopAlpha < 0) {
        this.stopCompleted();
        return;
      }
    } else if (millis() - startMillis < 2000) {
      startStopAlpha = min(1.0, (millis() - startMillis) / 2000.0);
    }
    
    float prevAmp = -1;
    float waveformAlpha = 0.5 * volumeAlpha * startStopAlpha;
    
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
        stroke(hue % 100, 100, 100, 100 * waveformAlpha);
        
        line(displayWidth / 2.0 + stretch * i - stretch, prevAmp, displayWidth / 2.0 + stretch * i, amp);
        line(displayWidth / 2.0 - stretch * i + stretch, prevAmp, displayWidth / 2.0 - stretch * i, amp);
      }
      
      prevAmp = amp;
    }
  }
}
