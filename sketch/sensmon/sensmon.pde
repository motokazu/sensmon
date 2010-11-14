/*
  sensmon arduino sketch.
 
 created 14 Nov 2010.
 by Motokazu Nishimura.
 */

#include <SPI.h>

#include <Ethernet.h>
#include <string.h>

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 192, 168, 0, 50 };
byte gw[] = { 192, 168, 0, 1 };
byte subnet[] = { 255, 255, 255, 0 };
byte server[] = { 192, 168, 0, 80 }; // sheevabian

unsigned long count = 0;

void setup()
{
  Ethernet.begin(mac, ip, gw, subnet);
  Serial.begin(9600);
  
  delay(1000);
  
  Serial.println("Startup Sensmon. let's relax arduino.");
}

boolean post()
{
  char json[256];
  char q = '"';
  char clength[30];
  
  int sensorValue = analogRead(0);
  
  // reverse
  sensorValue = 1024 - sensorValue;

  sprintf(json,"{%cstime%c:%c%ld%c, %cvalue%c:%d}",q,q,q,count,q,q,q,sensorValue);
  Serial.println(json);
  count ++ ;
  
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
  post();
  delay(1000);
}

