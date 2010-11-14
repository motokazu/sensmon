/*
  sensmon arduino sketch.
 
 created 14 Nov 2010.
 by Motokazu Nishimura.
 */

#include <SPI.h>

#include <Ethernet.h>
#include <string.h>
#include <Time.h>

#define TIME_MSG_LEN  11   // time sync to PC is HEADER followed by Unix time_t as ten ASCII digits
#define TIME_HEADER  'T'   // Header tag for serial time sync message
#define TIME_REQUEST  7    // ASCII bell character requests a time sync message 

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 192, 168, 0, 50 };
byte gw[] = { 192, 168, 0, 1 };
byte subnet[] = { 255, 255, 255, 0 };
byte server[] = { 192, 168, 0, 80 }; // sheevabian

void setup()
{
  Ethernet.begin(mac, ip, gw, subnet);
  Serial.begin(9600);
  
  delay(1000);
  
  Serial.println("Startup Sensmon. let's relax arduino.");
  setSyncProvider( requestSync);  //set function to call when sync required
  Serial.println("Waiting for sync message from Serial msg.");
}

boolean post()
{
  char json[256];
  char q = '"';
  char clength[30];
  char timestr[20];
  
  int sensorValue = analogRead(0);
  
  // reverse
  sensorValue = 1024 - sensorValue;
  
  sprintf(timestr,"%04d/%02d/%02d %02d:%02d:%02d",year(),month(),day(),hour(),minute(),second());
  Serial.println(timestr);
 
  sprintf(json,"{%cstime%c:%c%s%c, %cvalue%c:%d}",q,q,q,timestr,q,q,q,sensorValue);
  Serial.println(json);
  
  Client client(server, 5984); // connect couchdb
  Serial.println("connecting couchdb...");
  
  if(client.connect()){
    Serial.println("connected");
    client.println("POST /sensmon HTTP/1.1");
    client.println("Host: sheevabian");
    client.println("Authorization: Basic bW90b2thenU6YXNkZmFzZGY=");
    client.println("Content-Type: application/json");
    sprintf(clength,"Content-Length: %d",strlen(json));
    client.println(clength);
    client.println("Connection: Close");
    client.println();
    client.print(json);
    Serial.println("POST OK");
  } else {
    Serial.println("connection failed");
    return false;
  }              
  client.stop();
  return true;
}

void loop()
{
  if(Serial.available() ) {
    processSyncMessage();
  }
  if(timeStatus()!= timeNotSet) {
    post();
  }
  delay(60000);
}

void processSyncMessage() {
  // if time sync available from serial port, update time and return true
  while(Serial.available() >=  TIME_MSG_LEN ){  // time message consists of header & 10 ASCII digits
    char c = Serial.read() ; 
    Serial.print(c);  
    if( c == TIME_HEADER ) {       
      time_t pctime = 0;
      for(int i=0; i < TIME_MSG_LEN -1; i++){   
        c = Serial.read();          
        if( c >= '0' && c <= '9'){   
          pctime = (10 * pctime) + (c - '0') ; // convert digits to a number    
        }
      }   
      setTime(pctime);   // Sync Arduino clock to the time received on the serial port
    }  
  }
}


time_t requestSync()
{
  Serial.print(TIME_REQUEST,BYTE);  
  return 0; // the time will be sent later in response to serial mesg
}
