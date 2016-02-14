import oscP5.*;
import netP5.*;
OscP5 oscP5;

final int NUMCHANNELS= 3;  //should correspond with numChannels in supercollider
final int BUFFERSIZE= 735;  //should correspond with bufferSize in supercollider

float[][] waveData;
float[][] ctrlData;
int feedback= 0;
int w3, h3;
int alpha= 50;
int dx;

void setup() {
  fullScreen(FX2D, 2);
  //size(1920, 1080, FX2D);
  frameRate(60);
  background(0);

  waveData= new float[NUMCHANNELS][BUFFERSIZE];  //sound samples
  ctrlData= new float[NUMCHANNELS][2];  //accelerometer
  for (int i= 0; i<NUMCHANNELS; i++) {
    for (int j= 0; j<BUFFERSIZE; j++) {
      waveData[i][j]= 0.0;
    }
    ctrlData[i][0]= 0.0;
    ctrlData[i][1]= 0.0;
  }

  OscProperties properties= new OscProperties();
  properties.setListeningPort(47130);  //osc receive port (from sc)
  properties.setDatagramSize(5136);  //5136 is the minimum
  oscP5= new OscP5(this, properties);

  w3= int(width*0.33);
  h3= int(height*0.33);
  dx= int(width*(1.0/float(NUMCHANNELS+1)));  //channel spread
}

void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/waveData")) {
    //format: [channel_index, accel_x, accel_y, sound_samples...]
    int i= msg.get(0).intValue();  //index
    ctrlData[i][0]= msg.get(1).floatValue();  //cxBus
    ctrlData[i][1]= msg.get(2).floatValue();  //cyBus
    for (int j= 0; j<BUFFERSIZE; j++) {
      waveData[i][j]= msg.get(j+3).floatValue();
    }
  } else if (msg.checkAddrPattern("/alpha")) {
    //format: [alpha(0-255)] where 255 is off (no trails)
    alpha= msg.get(0).intValue();
  } else if (msg.checkAddrPattern("/feedback")) {
    //format: [feedback(0|1)]
    feedback= msg.get(0).intValue();
  }
}

void draw() {
  noStroke();
  fill(0, alpha);  //trails
  rect(0, 0, width, height);

  if (feedback>0) {
    image(get(w3, h3, w3, h3), 0, 0, width, height);
  }

  translate(0, height*0.5);
  stroke(0, 255, 0);
  fill(255);
  //float xx= map(mouseX, 0, width, -10*PI, 10*PI);
  //float yy= map(mouseY, 0, height, 0, 5*PI);
  for (int i= 0; i<NUMCHANNELS; i++) {
    translate(dx, 0);
    float xx= ctrlData[i][0];
    float yy= ctrlData[i][1];
    for (int j= 0; j<BUFFERSIZE; j++) {
      float t= j/float(BUFFERSIZE);
      float a= waveData[i][j]*100.0;
      float x= sin(t*xx)*200.0+a;
      float y= cos(t*yy)*300.0;
      float r= max(1, abs(a)*0.08);
      ellipse(x, y, r, r);
    }
  }
}