/**********************************************/
//  
//    
//
//  Program name: Aigamozu Processing
//  Author: Haruna Nakazawa
//  Ver ->  1.0
//  Day ->  2016/09/17
//  
//
/**********************************************/


import processing.serial.*;
import java.awt.event.*;
import java.nio.*;
import controlP5.*;

//************ User setting *****************
//Robot   ID: A ~ Z
//Base    ID: a ~ a

byte robotId[] = {C};
byte baseId[] = {a, b, c, d};

//*******************************************

Serial port;
int request_timer;
boolean plot_flag = false;
byte[] packet;
int num=1;

static final float basePos[][] = new float[4][2];
Textfield basePosText[][] = new Textfield[4][2];

float referenceX = 0.0, referenceY = 0.0;
double x_scale_min=0.0, x_scale_max=0.0, y_scale_min=0.0, y_scale_max=0.0;

aigamozuData base[] = new aigamozuData[baseId.length];
aigamozuData robot[] = new aigamozuData[robotId.length];

ControlP5 cp5;
ControlP5 Button;
PFont pfont;
PFont pfont2;


public void setup(){
  size(1500, 1000);
  textSize(30);
  surface.setResizable(false);
  background(255);
  
  port = new Serial(this,"COM11",57600);
  pfont = createFont("Arial",20,true);
  pfont2 = createFont("Arial",35,true);
  
  for(int i=0; i<robotId.length; i++){
    robot[i] = new aigamozuData(robotId[i], i);
  }
  for(int i=0; i<baseId.length; i++){
    base[i] = new aigamozuData(baseId[i], 0);
  }
  
  setConfig();
  println("start");
}

public void draw(){

  //println(baseFlag);
  request_timer = millis();
  
  infoDraw();
  if(request_timer >= 1000 * num){
    request();
    num++;
  }
  
  for(int i=0; i<baseId.length; i++){
    fill(255);
    stroke(255);
    rect(width-400, height/2+105+85*i, 150, 30);
    rect(width-200, height/2+105+85*i, 150, 30);
    fill(0);
    textSize(24);
    text(nf((float)base[i].getLongitude(), 3, 6), width-390, height/2+125+85*i);
    text(nf((float)base[i].getLatitude(), 2, 6), width-190, height/2+125+85*i);
  }
    
  // get packet
  if(port.available() > 0) {
    // get and store packet
    getPacket();

  }  
} 

public void stop(){
  
  for(int i=0; i<robotId.length; i++){
    robot[i].closeFile();
  }
  for(int i=0; i<baseId.length; i++){
    base[i].closeFile();
  }
}

void defaultView(){
  fill(0x00, 0x00, 0xCD);
  stroke(0x00, 0x00, 0xCD);
  strokeWeight(10);
  line(1000, 0, 1000, 1000);
  line(1000, 500, 1500, 500);
  textSize(30);
  text("Plot", 20, 40);
  text("Robot Color", 1020, 40);
  text("Configuration", 1020, 540); 
  
  for(int i=0; i<4; i++){
    fill(0);
    text(char(0x61+i),width-450, height/2+95+85*i);
  }
}

void setConfig(){
  
 defaultView();

 cp5 = new ControlP5(this); 
  
//Textfield for longitude and latitude
for(int i = 0; i < 4; i ++){
  for (int j = 0; j < 2; j ++){ 
    //basePos[i][j] = 0.0;
    // basePosText[i][j].setColorBackground(color(1,1,1));
    if(j%2 == 0){
    basePosText[i][j] = cp5.addTextfield(str(i))
                           .setPosition(width - 400,height/2 + 70 + 85*i)
                           .setFont(pfont)
                           .setColorBackground(color(0x87,0xCE,0xFA))
                           .setColor(0)
                           .setSize(150,30)
                           .setAutoClear(false)
                           .setInputFilter(ControlP5.FLOAT)
                           .setText("0");
                           
    
                    
    }
    else{
    basePosText[i][j] = cp5.addTextfield(str(i+baseId.length))
                           .setPosition(width - 200,height/2 + 70+85*i)
                           .setFont(pfont)
                           .setColorBackground(color(0x87,0xCE,0xFA))
                           .setColor(0)
                           .setSize(150,30)
                           .setAutoClear(false)
                           .setInputFilter(ControlP5.FLOAT)
                           .setText("0");
    }
  }
}

//config Button
Button = new ControlP5(this);
Button.addButton("config")      
      .setPosition(width - 370,height - 70)
      .setFont(pfont2)
      .setColorBackground(color(0x1E,0x90,0xFF))
      .setSize(300,50)
      .setLabel("Config");

}

public void infoDraw(){
  
  for(int i=0; i<robotId.length; i++){
    fill(0);
    textSize(25);
    text(robot[i].getId(), 1050, 100+50*i);
    int rectC[] = robot[i].getRGB();
    noStroke();
    fill(rectC[0], rectC[1], rectC[2]);
    rect(1100, 75+50*i, 100, 30);
  }
}

public void request(){
  // request to robot
    for(int i=0; i<robotId.length; i++){
      robot[i].sendRequestRobot();
    }
    for(int i=0; i<baseId.length; i++){
      base[i].sendRequestBase();
    }
}

public void calcScale(){
  double dX[] = new double[baseId.length];
  double dY[] = new double[baseId.length];
  double x_min=0.0, x_max=0.0, y_min=0.0, y_max=0.0;
  double x_scale=0.0, y_scale=0.0;
  
  background(255);
  defaultView();
  
  println("calcScale");
  
  referenceX = basePos[0][0];
  referenceY = basePos[0][1];
  
  for(int i=0; i<baseId.length; i++){
    dX[i] = calc_distanceX(basePos[i][0], referenceX);
    dY[i] = calc_distanceY(basePos[i][1], referenceY);
  
    if(dX[i] < x_min) x_min = dX[i];
    if(dX[i] > x_max) x_max = dX[i];
    if(dY[i] < y_min) y_min = dY[i];
    if(dY[i] > y_max) y_max = dY[i];
  }
  
  x_scale = (x_max-x_min)/5.0;
  y_scale = (y_max-y_min)/5.0;
  
  if(x_scale > y_scale) {
    x_scale_min = x_min - x_scale;
    x_scale_max = x_scale_min + x_scale * 7;
    y_scale_min = y_min - y_scale;
    y_scale_max = y_scale_min + x_scale * 7;
  }
  else {
    x_scale_min = x_min - x_scale;
    x_scale_max = x_scale_min + y_scale * 7;
    y_scale_min = y_min - y_scale;
    y_scale_max = y_scale_min + y_scale * 7;
  }

  // cordinate transform
  for(int i=0; i<baseId.length; i++){
      base[i].setX(map((float)dX[i], (float)x_scale_min, (float)x_scale_max, 0, 1000));
      base[i].setY(map((float)dY[i], (float)y_scale_min, (float)y_scale_max, 1000, 0));
      basePlot(i);
  }
}

public void robotCordinateTrans(int i){
  
  double dX = calc_distanceX((float)robot[i].getLongitude(), referenceX);
  double dY = calc_distanceY((float)robot[i].getLatitude(), referenceY);
  
  if(dX != 0.0 && dY != 0.0){
    robot[i].setX(map((float)dX, (float)x_scale_min, (float)x_scale_max, 0, 1000));
    robot[i].setY(map((float)dY, (float)y_scale_min, (float)y_scale_max, 1000, 0));
  }
}

public float calc_distanceX(float x1, float x2){
  float dx = x1 - x2;
  float A = 6378137;
  return A * dx * abs(cos(radians((x1+x2)/2)));
}

public float calc_distanceY(float y1, float y2){
  float dy = y1 - y2;
  float A = 6378137;
  return A * dy;
}

public void robotPlot(int i){
  double x, y, px, py;
  
  println("robot plot");
  println(robot[i].getId() + " " + robot[i].getLongitude() + " " + robot[i].getLatitude());
  robotCordinateTrans(i);
  
  x = robot[i].getX();
  y = robot[i].getY();
  px = robot[i].getPreviousX();
  py = robot[i].getPreviousY();
    
  int rgb[] = robot[i].getRGB();
  stroke(rgb[0], rgb[1], rgb[2]);
  cross((float)x, (float)y);
  beginShape(LINES);
  vertex((float)px, (float)py);
  vertex((float)x, (float)y);
  endShape();
  robot[i].colorGradation();
}
 
public void basePlot(int i){
  double x, y;
  println("base plot");
  plot_flag = true;
  x = base[i].getX();
  y = base[i].getY();
  fill(0);
  text(base[i].getId(), (float)x-20, (float)y-20);
  stroke(0);
  triangle((float)x, (float)y-10, (float)x-4, (float)y-2, (float)x+4, (float)y-2);
}

public void cross(float x, float y){
  strokeWeight(2);
  strokeCap(ROUND);
  line(x-5, y-5, x+5, y+5);
  line(x-5, y+5, x+5, y-5);
}

public void getPacket(){
  // PacketIndex and Flag
  int packetLength = 0;
  int startIdx = 0;
  int endIdx = 0;
  int gpsIdx = 0;
  int startFlag = 0;
  int endFlag = 0;
  int gpsFlag = 0;
  
  try{
   if(port.read() == 0x7E){
    //byteCounter = 0;
    
    packet = port.readBytes();
    for(int i = 0; i < packet.length;i++){
      if(i == 1) {
        packetLength = i;
        }
      //search "AGS"
      if(packet[i] == 0x41 && packet[i+1] == 0x47 && packet[i+2] == 0x53) {
         startFlag = 1;
         startIdx = i;
         //println("startIdx : "+startIdx);
      }
      //serch "GPS"
      if(packet[i] == 0x47 && packet[i+1] == 0x50 && packet[i+2] == 0x53){
        gpsFlag = 1;
        gpsIdx = i+3;
        //println("gpsIdx:",gpsIdx);
      }
      //serch "AGE"
      if(packet[i] == 0x41 && packet[i+1] == 0x47 && packet[i+2] == 0x45){
        endFlag = 1;
        endIdx = i+2;
        //println("endIdx : "+endIdx);
      }
       //all flags == 1 
      if(startFlag == 1 && endFlag == 1 && gpsFlag == 1){
        //pass
        startFlag = 0;
        endFlag = 0;
        gpsFlag = 0;
        //println(packet);
        //println(char(packet[startIdx+5]) + request_timer);
        
        // store robot data
        if (A <= packet[startIdx+5] && packet[startIdx+5] <= Z){
          for(int j=0; j<robotId.length; j++){
            if(packet[startIdx+5] == robot[j].getId()){
              robot[j].dataSetting(packet, startIdx, endIdx, gpsIdx);
              if(plot_flag) robotPlot(j);
              break;
            }
          }
        }
        // store base data
        else if(a <= packet[startIdx+5] && packet[startIdx+5] <= z){
          for(int j=0; j<baseId.length; j++){
            if(packet[startIdx+5] == base[j].getId()){
              base[j].dataSetting(packet, startIdx, endIdx, gpsIdx);
              println(base[j].getId() + " " + base[j].getLongitude() + " " + base[j].getLatitude());
              break;
            }
          }
        }
      }
    }
   }
  }
  catch(Exception e){
    //println(e);
  }
}

///////////////////////////////////////////////
//
//if you press 'CONFIG' button, an action occur
//
///////////////////////////////////////////////

void config(){
  for(int i = 0; i < baseId.length; i ++){
    basePosText[i][0].setAutoClear(false);
    basePosText[i][1].setAutoClear(false);
    
    basePos[i][0] = float(nf((float)base[i].getLongitude(), 3, 6));
    basePos[i][1] = float(nf((float)base[i].getLatitude(), 3, 6));
    
    basePosText[i][0].setText(str(basePos[i][0]));
    basePosText[i][1].setText(str(basePos[i][1]));

    println("base" + i + "longi"+basePos[i][0] + "  " + 
              "base" + i + "lati"+basePos[i][1]);
  }
  calcScale();
}
////////////////////////////////////
//
//if you press Enter,an action occur.
//
///////////////////////////////////
/*void keyPressed(){
  if(key == ENTER){
    for(int i = 0; i < 4; i ++){
    basePosText[i][0].setAutoClear(false);
    basePosText[i][1].setAutoClear(false);
    basePosText[i][0].setFont(pfont);
    basePosText[i][1].setFont(pfont);
    basePos[i][0] = float(basePosText[i][0].getText());
    basePos[i][1] = float(basePosText[i][1].getText());
    println("base"+i+"longi"+basePos[i][0]+"  "+
            "base"+i+"lati"+basePos[i][1]);
    }
  }
}*/

class WindowListener extends WindowAdapter{
  public void windowClosing(WindowEvent e){
    stop();
    System.exit(0);
  }
}