

class aigamozuData{
  private PrintWriter outfile;
  
  private byte[] gpsPacket = new byte[16];
  private int startPacketIdx;
  private int endPacketIdx;
  private int gpsPacketIdx;
  private char id;
  private double longitude = 0.0;
  private double latitude = 0.0;
  private double x[] = {0.0, 0.0};
  private double y[] = {0.0, 0.0};
 
 // member to gradate color
  private int colorNum;
  private int rgb[] = new int[3];
  private int grad;
  private int gradFlag = 0;  //0->+, 1->-
  
  /////////////////////////////////////
  //
  //  Constructor
  //
  /////////////////////////////////////
  
  public aigamozuData(byte id, int colorNum){
    this.id = char(id);
    this.colorNum = colorNum;
    
    outfile = createWriter(nf(year(),4) + "-" + nf(month(),2) + "-" + nf(day(),2) + "/" 
    + this.id + "_" + nf(year(),4) + nf(month(),2) + nf(day(),2) + "_JST(+09)" + nf(hour(),2) + nf(minute(),2) + ".csv");
    
    if(0 <= colorNum && colorNum <= 2){
      grad = 0;
    }
    else if(3 <= colorNum && colorNum <= 5){
      grad = 255;
    }
    
    setColor();
  }

  /////////////////////////////////////
  //
  //  receive data
  //
  /////////////////////////////////////
  public void dataSetting(byte[] p, int start, int end, int gps){
    byte [] array = p;
    startPacketIdx = start;
    endPacketIdx = end;
    gpsPacketIdx = gps;
    
    
    // ESC process 
    boolean eFlag = false;
    int j=gpsPacketIdx;
    for(int i=0; i<16; i++, j++){
      if(array[j] == 0x7D){
        eFlag = true;
      }
      if(eFlag){
        if(array[j] == 0x7D){
          gpsPacket[i] = byte(array[j+1] ^ 32);
          j++;
        }
        else{
          gpsPacket[i] = array[j];
        }
      }
      else{
        gpsPacket[i] = array[j];
      }
    }
    
    setLongitude();
    setLatitude();
    
    colorGradation();
    
    writeData();
    updateXY();
    
  } 
  
  /////////////////////////////////////
  //
  //  write to file
  //
  /////////////////////////////////////
  public void writeData(){
    outfile.println(id + ", " + longitude + ", " + latitude);
    outfile.flush();
    //println(id + ", " + longitude + ", " + latitude);
  }
  
  /////////////////////////////////////
  //
  //  close file
  //
  /////////////////////////////////////  
  public void closeFile(){
    outfile.close();
  }
  
  
  /////////////////////////////////////
  //
  //  request to robot and base
  //
  /////////////////////////////////////
    public void sendRequestRobot(){
    
    int addr = char(id) - 'A';
    int checksum = 0x10 + 0x01 + 0xFF + 0xFE + A + G + S + S + F + A + T + id + A + G + E;
    for(int i=0; i<8; i++){
      checksum += robotAddr[addr][i];
    }
    checksum = 0xFF - (checksum & 0x00FF);
    
    byte [] requestPacket = {byte(0x7E), byte(0x00), byte(0x19), byte(0x10), byte(0x01), 
                             robotAddr[addr][0], robotAddr[addr][1], robotAddr[addr][2], robotAddr[addr][3], 
                             robotAddr[addr][4], robotAddr[addr][5], robotAddr[addr][6], robotAddr[addr][7],
                             byte(0xFF), byte(0xFE), byte(0x00), byte(0x00), A, G, S, 
                             S, F, A, T, byte(id), A, G, E, byte(checksum)};
  
  
  /*checksum = 0x10 + 0x01 + 0xFF + 0xFF + 0xFF + 0xFE + A + G + S + S + F + A + T + byte(id) + A + G + E;
  checksum = 0xFF - (checksum & 0x00FF);
    
    byte [] requestPacket = {byte(0x7E), byte(0x00), byte(0x19), byte(0x10), byte(0x01), 
                             byte(0x00), byte(0x00), byte(0x00), byte(0x00), 
                             byte(0x00), byte(0x00), byte(0xFF), byte(0xFF),
                             byte(0xFF), byte(0xFE), byte(0x00), byte(0x00), A, G, S, 
                             S, F, A, T, byte(id), A, G, E, byte(checksum)};
    */port.write(requestPacket);
  }
  public void sendRequestBase(){
    
    int addr = char(id) - 'a';
    int checksum = 0x10 + 0x01 + 0xFF + 0xFE + A + G + S + S + F + A + T + byte(id)+ A + G + E;
    for(int i=0; i<8; i++){
      checksum += baseAddr[addr][i];
    }
    checksum = 0xFF - (checksum & 0x00FF);
    
    byte [] requestPacket = {byte(0x7E), byte(0x00), byte(0x19), byte(0x10), byte(0x01), 
                             baseAddr[addr][0], baseAddr[addr][1], baseAddr[addr][2], baseAddr[addr][3], 
                             baseAddr[addr][4], baseAddr[addr][5], baseAddr[addr][6], baseAddr[addr][7],
                             byte(0xFF), byte(0xFE), byte(0x00), byte(0x00), A, G, S, 
                             S, F, A, T, byte(id), A, G, E, byte(checksum)};
  
    port.write(requestPacket);
  }
  
  /////////////////////////////////////
  //
  //  Color gradation
  //
  /////////////////////////////////////
  public void colorGradation(){
    if(gradFlag == 0){
      grad+=2;
    }
    else if(gradFlag == 1){
      grad-=2;
    }
    if((grad>=255) || (grad<=0)){
      gradFlag = (gradFlag+1) % 2;
    }
    
    setColor();
  }
  
  /////////////////////////////////////
  //
  //  Update X, Y
  //
  /////////////////////////////////////  
  
  public void updateXY(){
    x[1] = x[0];
    y[1] = y[0];
  }
  
  /////////////////////////////////////
  //
  //  Set
  //
  /////////////////////////////////////
    
    public void setLongitude(){
    try{
      
      byte [] data = {byte(gpsPacket[8]), byte(gpsPacket[9]), byte(gpsPacket[10]), byte(gpsPacket[11]), 
                      byte(gpsPacket[12]), byte(gpsPacket[13]), byte(gpsPacket[14]), byte(gpsPacket[15])};
      
     // if(data[7] == 0x40){
        ByteBuffer buf = ByteBuffer.wrap(data);
        buf.order(ByteOrder.LITTLE_ENDIAN);
        longitude = buf.getDouble();
      
        //println("longitude: " + longitude);
     // }
    }
    catch(Exception e){
      println("setlongitude: " + e);
    }
  }
  
  public void setLatitude(){
    try{
      
      byte [] data = {byte(gpsPacket[0]), byte(gpsPacket[1]), byte(gpsPacket[2]), byte(gpsPacket[3]), 
                      byte(gpsPacket[4]), byte(gpsPacket[5]), byte(gpsPacket[6]), byte(gpsPacket[7])};
      
      if(data[7] == 0x40){
        ByteBuffer buf = ByteBuffer.wrap(data);
        buf.order(ByteOrder.LITTLE_ENDIAN);
        latitude = buf.getDouble();
      
        //println("latitude: " + latitude);
      }
    }
    catch(Exception e){
      println("setLatitude: " + e);
    }
  }
  
  public void setX(double x){    
    if((this.x[0] == 0.0) && (this.x[1] == 0.0)){
      this.x[0] = x;
      this.x[1] = x;
    }
    else{
      this.x[0] = x;
    }
    //println("setX()->" + id + ": " + this.x[0] + ", " + this.x[1]);
  }
  
  public void setY(double y){
    if((this.y[0] == 0.0) && (this.y[1] == 0.0)){
      this.y[0] = y;
      this.y[1] = y;
    }
    else{
      this.y[0] = y;
    }
  }
  
  public void setColor(){
    switch(colorNum){
      case 0:
        rgb[0] = 255; rgb[1] = 0; rgb[2] = grad;
        break;
      case 1:
        rgb[1] = grad; rgb[1] = 255; rgb[2] = 0;
        break;
      case 2:
        rgb[2] = 0; rgb[1] = grad; rgb[2] = 255;
        break;
      case 3:
        rgb[0] = 255; rgb[1] = grad; rgb[2] = 0;
        break;
      case 4:
        rgb[0] = 0; rgb[1] = 255; rgb[2] = grad;
        break;
      case 5:
        rgb[0] = grad; rgb[1] = 0; rgb[2] = 255;
        break;
      case -1:
        break;
    }
  }
    
    
  /////////////////////////////////////
  //
  //  Get
  //
  /////////////////////////////////////
  
  public char getId(){
    return id;
  }
  
  public int[] getRGB(){
    return rgb;
  }
  
  public double getLongitude(){
    return longitude;
  }
  
  public double getLatitude(){
    return latitude;
  }
  
  public double getX(){
    return x[0];
  }
  
  public double getY(){
    return y[0];
  }
  
  public double getPreviousX(){
    return x[1];
  }
  
  public double getPreviousY(){
    return y[1];
  }
  
}